# Module Dependency Diagram Generator
#
# Usage:
#   nix eval --impure --raw --expr "import ./scripts/generate-diagram.nix { lib = (import <nixpkgs> {}).lib; modulesDir = ./modules; }" > docs/module-diagram.md
#
# This generates a Mermaid diagram showing:
# - Hosts (darwin/nixos) and their module imports
# - Users and their home-manager module imports
# - Transitive dependencies between modules
#
# The diagram is output as a markdown file that can be rendered by
# GitHub, VS Code (with Mermaid extension), or any Mermaid renderer.

{
  lib,
  modulesDir,
  showSecrets ? false,
}:

let
  # Helper: take elements from list while predicate is true
  takeWhile =
    pred: list:
    let
      go =
        acc: remaining:
        if remaining == [ ] then
          acc
        else if pred (builtins.head remaining) then
          go (acc ++ [ (builtins.head remaining) ]) (builtins.tail remaining)
        else
          acc;
    in
    go [ ] list;

  # Recursively read directory, returning list of { path, name }
  readDirRecursive =
    path:
    let
      entries = builtins.readDir path;
      processEntry =
        name: type:
        let
          fullPath = "${path}/${name}";
        in
        if type == "directory" && !(lib.hasPrefix "_" name) then
          readDirRecursive fullPath
        else if type == "regular" && lib.hasSuffix ".nix" name && !(lib.hasPrefix "_" name) then
          [
            {
              path = fullPath;
              name = name;
            }
          ]
        else
          [ ];
    in
    lib.concatLists (lib.mapAttrsToList processEntry entries);

  allFiles = readDirRecursive modulesDir;

  # Filter out comment lines
  stripComments =
    lines:
    map (
      l:
      let
        stripped = lib.trim l;
      in
      if lib.hasPrefix "#" stripped then "" else stripped
    ) lines;

  # Extract fully-qualified imports: config.flake.modules.<class>.<name>
  extractDirectImports =
    content:
    let
      lines = stripComments (lib.splitString "\n" content);
      pattern = ".*config[.]flake[.]modules[.](darwin|nixos|homeManager)[.]\"?([a-zA-Z0-9_-]+)\"?.*";
      matches = builtins.filter (m: m != null) (map (l: builtins.match pattern l) lines);
    in
    map (m: {
      class = builtins.elemAt m 0;
      name = builtins.elemAt m 1;
    }) matches;

  # Extract bare names after `with config.flake.modules.<class>;`
  extractWithImports =
    content:
    let
      lines = lib.splitString "\n" content;
      withPattern = ".*with[[:space:]]+config[.]flake[.]modules[.](darwin|nixos|homeManager)[[:space:]]*;.*";
      barePattern = "^[[:space:]]*\"?([a-zA-Z0-9_-]+)\"?[[:space:]]*$";

      # Find with lines and their classes
      withIndices = lib.imap0 (
        i: line:
        let
          m = builtins.match withPattern line;
        in
        if m != null then
          {
            index = i;
            class = builtins.elemAt m 0;
          }
        else
          null
      ) lines;
      realWithIndices = builtins.filter (x: x != null) withIndices;

      # For each with line, collect bare names until ];
      collectBareNames =
        wi:
        let
          startIdx = wi.index + 1;
          remaining = lib.drop startIdx lines;
          # Take lines until we hit ];
          blockLines = takeWhile (
            l: !(lib.hasSuffix "];" (lib.trim l)) && !(lib.hasSuffix "]" (lib.trim l))
          ) remaining;
          allBlockLines =
            blockLines
            ++ (
              let
                closingIdx = builtins.length blockLines;
              in
              if closingIdx < builtins.length remaining then [ (builtins.elemAt remaining closingIdx) ] else [ ]
            );
          bareMatches = builtins.filter (m: m != null) (map (l: builtins.match barePattern l) allBlockLines);
        in
        map (m: {
          class = wi.class;
          name = builtins.elemAt m 0;
        }) bareMatches;

    in
    lib.concatMap collectBareNames realWithIndices;

  # Extract module definitions: flake.modules.<class>.<name> = ...
  extractModuleDefs =
    content:
    let
      lines = stripComments (lib.splitString "\n" content);
      pattern = ".*flake[.]modules[.](darwin|nixos|homeManager)[.]\"?([a-zA-Z0-9_-]+)\"?[[:space:]]*=.*";
      matches = builtins.filter (m: m != null) (map (l: builtins.match pattern l) lines);
    in
    map (m: {
      class = builtins.elemAt m 0;
      name = builtins.elemAt m 1;
    }) matches;

  # Extract host configs: configurations.<class>.<hostname>.module
  extractHostConfigs =
    content:
    let
      lines = stripComments (lib.splitString "\n" content);
      pattern = ".*configurations[.](darwin|nixos)[.]([A-Za-z0-9_-]+)[.]module.*";
      matches = builtins.filter (m: m != null) (map (l: builtins.match pattern l) lines);
    in
    map (m: {
      class = builtins.elemAt m 0;
      host = builtins.elemAt m 1;
    }) matches;

  # Extract user assignments: home-manager.users.${config.flake.meta.users.<name>.name}
  extractUserAssignments =
    content:
    let
      lines = stripComments (lib.splitString "\n" content);
      pattern = ".*home-manager[.]users[.]\\$[{]config[.]flake[.]meta[.]users[.]([a-zA-Z0-9_-]+)[.]name[}].*";
      matches = builtins.filter (m: m != null) (map (l: builtins.match pattern l) lines);
    in
    map (m: builtins.elemAt m 0) matches;

  # Extract user metadata from nested structure
  # Looking for: flake.meta.users.<name> = { ... description = "..."; ... };
  extractUserMeta =
    content:
    let
      lines = stripComments (lib.splitString "\n" content);
      # Find user blocks: flake.meta.users.<name> = {
      userBlockPattern = ".*flake[.]meta[.]users[.]([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*\\{.*";
      descPattern = ".*description[[:space:]]*=[[:space:]]*\"([^\"]+)\".*";

      # Find all user block starts
      userBlocks = lib.imap0 (
        i: line:
        let
          m = builtins.match userBlockPattern line;
        in
        if m != null then
          {
            index = i;
            userName = builtins.elemAt m 0;
          }
        else
          null
      ) lines;
      realUserBlocks = builtins.filter (x: x != null) userBlocks;

      # For each user block, find the description within the next 20 lines
      extractDesc =
        block:
        let
          startIdx = block.index + 1;
          searchRange = lib.take 20 (lib.drop startIdx lines);
          descMatch = builtins.filter (m: m != null) (map (l: builtins.match descPattern l) searchRange);
        in
        if descMatch != [ ] then
          { ${block.userName}.description = builtins.elemAt (builtins.head descMatch) 0; }
        else
          { };
    in
    lib.foldl' (acc: block: acc // (extractDesc block)) { } realUserBlocks;

  # Extract NixOS-level secrets: services.onepassword-secrets.secrets = { <name> = { ... }; };
  extractNixosSecrets =
    content:
    let
      lines = lib.splitString "\n" content;
      # Find the start of secrets block
      startPattern = ".*services[.]onepassword-secrets[.]secrets[[:space:]]*=[[:space:]]*\\{.*";
      # Find secret names within the block (lines like "  beszelEmail = {")
      secretPattern = "^[[:space:]]+([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*\\{.*";

      # Find all start positions (skip comment lines)
      startIndices = lib.imap0 (
        i: line:
        let
          stripped = lib.trim line;
        in
        if lib.hasPrefix "#" stripped then
          null
        else
          let
            m = builtins.match startPattern line;
          in
          if m != null then i else null
      ) lines;
      realStartIndices = builtins.filter (x: x != null) startIndices;

      # For each start, collect secret names by tracking brace depth
      collectSecrets =
        startIdx:
        let
          remaining = lib.drop (startIdx + 1) lines;
          # Start with depth 1 (inside the secrets = { block)
          # Stop when depth reaches 0
          go =
            depth: acc: remaining:
            if remaining == [ ] then
              acc
            else
              let
                line = builtins.head remaining;
                stripped = lib.trim line;
                # Skip comment lines
                isComment = lib.hasPrefix "#" stripped;
                # Count opening and closing braces (only in non-comment lines)
                openBraces = if isComment then 0 else builtins.length (lib.splitString "{" line) - 1;
                closeBraces = if isComment then 0 else builtins.length (lib.splitString "}" line) - 1;
                newDepth = depth + openBraces - closeBraces;
                # Check if this line defines a secret (only in non-comment lines)
                secretMatch = if isComment then null else builtins.match secretPattern line;
                newAcc = if secretMatch != null then acc ++ [ (builtins.elemAt secretMatch 0) ] else acc;
              in
              if newDepth <= 0 then newAcc else go newDepth newAcc (builtins.tail remaining);
        in
        go 1 [ ] remaining;
    in
    lib.concatMap collectSecrets realStartIndices;

  # Extract home-manager-level secrets: programs.onepassword-secrets.secrets = { <name> = { ... }; };
  extractHmSecrets =
    content:
    let
      lines = lib.splitString "\n" content;
      # Find the start of secrets block
      startPattern = ".*programs[.]onepassword-secrets[.]secrets[[:space:]]*=[[:space:]]*\\{.*";
      # Find secret names within the block (lines like "  githubToken = {")
      secretPattern = "^[[:space:]]+([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*\\{.*";

      # Find all start positions (skip comment lines)
      startIndices = lib.imap0 (
        i: line:
        let
          stripped = lib.trim line;
        in
        if lib.hasPrefix "#" stripped then
          null
        else
          let
            m = builtins.match startPattern line;
          in
          if m != null then i else null
      ) lines;
      realStartIndices = builtins.filter (x: x != null) startIndices;

      # For each start, collect secret names by tracking brace depth
      collectSecrets =
        startIdx:
        let
          remaining = lib.drop (startIdx + 1) lines;
          go =
            depth: acc: remaining:
            if remaining == [ ] then
              acc
            else
              let
                line = builtins.head remaining;
                stripped = lib.trim line;
                isComment = lib.hasPrefix "#" stripped;
                openBraces = if isComment then 0 else builtins.length (lib.splitString "{" line) - 1;
                closeBraces = if isComment then 0 else builtins.length (lib.splitString "}" line) - 1;
                newDepth = depth + openBraces - closeBraces;
                secretMatch = if isComment then null else builtins.match secretPattern line;
                newAcc = if secretMatch != null then acc ++ [ (builtins.elemAt secretMatch 0) ] else acc;
              in
              if newDepth <= 0 then newAcc else go newDepth newAcc (builtins.tail remaining);
        in
        go 1 [ ] remaining;
    in
    lib.concatMap collectSecrets realStartIndices;

  # Parse all files
  parsedFiles = map (
    file:
    let
      content = builtins.readFile file.path;
    in
    {
      inherit (file) path name;
      moduleDefs = extractModuleDefs content;
      directImports = extractDirectImports content;
      withImports = extractWithImports content;
      allImports = extractDirectImports content ++ extractWithImports content;
      hostConfigs = extractHostConfigs content;
      userAssignments = extractUserAssignments content;
      userMeta = extractUserMeta content;
      nixosSecrets = extractNixosSecrets content;
      hmSecrets = extractHmSecrets content;
    }
  ) allFiles;

  # Build user metadata from all files
  userMeta = lib.foldl' (acc: f: acc // f.userMeta) { } parsedFiles;

  # Build secrets-by-module map: { moduleName -> [secretName...] }
  # Maps each module to the secrets it declares (from both nixos and homeManager)
  secretsByModule =
    let
      # For each file, find which modules it defines and what secrets it declares
      fileSecrets = lib.concatMap (
        file:
        let
          nixosDefs = lib.filter (d: d.class == "nixos") file.moduleDefs;
          hmDefs = lib.filter (d: d.class == "homeManager") file.moduleDefs;
          # NixOS secrets go to nixos modules, HM secrets go to homeManager modules
          nixosSecretEntries = map (d: {
            module = "nixos-${d.name}";
            secrets = file.nixosSecrets;
          }) nixosDefs;
          hmSecretEntries = map (d: {
            module = "hm-${d.name}";
            secrets = file.hmSecrets;
          }) hmDefs;
          allEntries = nixosSecretEntries ++ hmSecretEntries;
        in
        lib.filter (e: e.secrets != [ ]) allEntries
      ) parsedFiles;
    in
    lib.foldl' (
      acc: entry: acc // { ${entry.module} = lib.unique ((acc.${entry.module} or [ ]) ++ entry.secrets); }
    ) { } fileSecrets;

  # All unique secret names (for node rendering)
  allSecretNames = lib.sort (a: b: a < b) (
    lib.unique (lib.concatLists (lib.attrValues secretsByModule))
  );

  # Build dependency map per class
  buildDepsMap =
    class:
    let
      fileDeps = lib.concatMap (
        file:
        let
          defs = lib.filter (d: d.class == class) file.moduleDefs;
          imports = lib.filter (i: i.class == class) file.allImports;
          importNames = lib.unique (map (i: i.name) imports);
        in
        map (d: {
          name = d.name;
          deps = importNames;
        }) defs
      ) parsedFiles;
    in
    lib.foldl' (
      acc: item: acc // { ${item.name} = lib.unique ((acc.${item.name} or [ ]) ++ item.deps); }
    ) { } fileDeps;

  darwinDeps = buildDepsMap "darwin";
  nixosDeps = buildDepsMap "nixos";
  homeManagerDeps = buildDepsMap "homeManager";

  # Get all hosts with their classes and users
  allHosts = lib.concatMap (
    file:
    let
      user = if file.userAssignments != [ ] then builtins.head file.userAssignments else null;
    in
    map (h: {
      inherit (h) class host;
      inherit user;
    }) file.hostConfigs
  ) parsedFiles;

  # Deduplicate hosts by host name (prefer entries with non-null users)
  hosts = builtins.attrValues (
    builtins.foldl' (
      acc: h:
      if acc ? ${h.host} then
        if acc.${h.host}.user == null && h.user != null then acc // { ${h.host} = h; } else acc
      else
        acc // { ${h.host} = h; }
    ) { } allHosts
  );

  # Filter out CI variants for cleaner diagram (they inherit from base host)
  realHosts = lib.filter (h: !(lib.hasSuffix "-CI" h.host)) hosts;

  # Get all unique user names from hosts
  userNames = lib.unique (builtins.filter (u: u != null) (map (h: h.user) realHosts));

  # Get module names
  darwinModuleNames = lib.sort (a: b: a < b) (lib.attrNames darwinDeps);
  nixosModuleNames = lib.sort (a: b: a < b) (lib.attrNames nixosDeps);
  hmModuleNames = lib.sort (a: b: a < b) (lib.attrNames homeManagerDeps);

  # Sanitize names for Mermaid IDs (replace special chars)
  sanitize = name: builtins.replaceStrings [ "\"" "-" "." ] [ "" "_" "_" ] name;

  # Generate Mermaid
  mermaid =
    let
      # Host nodes
      hostNodes = map (
        h:
        let
          icon = if h.class == "darwin" then "mac" else "linux";
          id = sanitize h.host;
        in
        "    ${id}[\"${icon} ${h.host}<br/><i>${h.class}</i>\"]"
      ) realHosts;

      # User nodes
      userNodes = map (
        name:
        let
          meta = userMeta.${name} or { };
          desc = meta.description or name;
        in
        "    ${name}[\"user ${name}<br/><i>${desc}</i>\"]"
      ) userNames;

      # Darwin module nodes
      darwinNodes = map (
        name:
        let
          id = "d-${sanitize name}";
        in
        "    ${id}[\"${name}\"]"
      ) darwinModuleNames;

      # NixOS module nodes
      nixosNodes = map (
        name:
        let
          id = "nixos-${sanitize name}";
        in
        "    ${id}[\"${name}\"]"
      ) nixosModuleNames;

      # HomeManager module nodes
      hmNodes = map (
        name:
        let
          id = "hm-${sanitize name}";
        in
        "    ${id}[\"${name}\"]"
      ) hmModuleNames;

      # Host → Darwin/NixOS module edges
      hostToModuleEdges = lib.concatMap (
        h:
        let
          hostFile = lib.findFirst (f: lib.any (hc: hc.host == h.host && hc.class == h.class) f.hostConfigs) {
            allImports = [ ];
          } parsedFiles;
          classImports = lib.filter (i: i.class == h.class) hostFile.allImports;
          importNames = lib.unique (map (i: i.name) classImports);
          prefix = if h.class == "darwin" then "d" else "nixos";
        in
        map (name: "    ${sanitize h.host} --> ${prefix}-${sanitize name}") importNames
      ) realHosts;

      # Host → User edges (only for hosts with users)
      hostToUserEdges = map (h: "    ${sanitize h.host} --> ${h.user}") (
        lib.filter (h: h.user != null) realHosts
      );

      # User → HomeManager module edges (from dependency map)
      userToModuleEdges = lib.concatMap (
        userName:
        let
          # Get the user's HM module dependencies
          userModuleDeps = homeManagerDeps.${userName} or [ ];
        in
        map (name: "    ${userName} --> hm-${sanitize name}") userModuleDeps
      ) userNames;

      # Darwin module → module edges (direct only, filter out self-references)
      darwinEdges = lib.concatLists (
        map (
          from:
          let
            direct = lib.filter (to: to != from) (darwinDeps.${from} or [ ]);
          in
          map (to: "    d-${sanitize from} --> d-${sanitize to}") direct
        ) darwinModuleNames
      );

      # NixOS module → module edges (direct only, filter out self-references)
      nixosEdges = lib.concatLists (
        map (
          from:
          let
            direct = lib.filter (to: to != from) (nixosDeps.${from} or [ ]);
          in
          map (to: "    nixos-${sanitize from} --> nixos-${sanitize to}") direct
        ) nixosModuleNames
      );

      # HomeManager module → module edges (direct only, filter out self-references)
      hmEdges = lib.concatLists (
        map (
          from:
          let
            direct = lib.filter (to: to != from) (homeManagerDeps.${from} or [ ]);
          in
          map (to: "    hm-${sanitize from} --> hm-${sanitize to}") direct
        ) hmModuleNames
      );

      # Secrets nodes (cylinder shape for visual distinction)
      secretNodes = map (
        name:
        let
          id = "secret-${sanitize name}";
        in
        "    ${id}[(\"${name}\")]"
      ) allSecretNames;

      # Module → Secret edges
      secretEdges = lib.concatLists (
        lib.mapAttrsToList (
          module: secrets: map (secret: "    ${module} --> secret-${sanitize secret}") secrets
        ) secretsByModule
      );

      # Conditional secrets section
      secretsSection =
        if showSecrets && allSecretNames != [ ] then
          ''
            subgraph secrets["Secrets (opnix)"]
              direction TB
            ${lib.concatStringsSep "\n" secretNodes}
            end

            %% Module to secret edges
            ${lib.concatStringsSep "\n" secretEdges}

            %% Secret styling
            classDef secret fill:#ffcdd2,stroke:#c62828,stroke-width:2px
            class ${lib.concatStringsSep "," (map (n: "secret-${sanitize n}") allSecretNames)} secret
          ''
        else
          "";

    in
    ''
      ---
      title: Nix Module Dependencies
      ---
      graph LR
        subgraph hosts["Hosts"]
          direction TB
      ${lib.concatStringsSep "\n" hostNodes}
        end

        subgraph users["Users"]
          direction TB
      ${lib.concatStringsSep "\n" userNodes}
        end

        subgraph systemModules["System Modules (darwin/nixos)"]
          direction TB
      ${lib.concatStringsSep "\n" darwinNodes}
      ${lib.concatStringsSep "\n" nixosNodes}
        end

        subgraph homeManager["HomeManager Modules"]
          direction TB
      ${lib.concatStringsSep "\n" hmNodes}
        end

        %% Host to system module edges
      ${lib.concatStringsSep "\n" hostToModuleEdges}

        %% Host to user edges
      ${lib.concatStringsSep "\n" hostToUserEdges}

        %% User to HomeManager module edges
      ${lib.concatStringsSep "\n" userToModuleEdges}

        %% System module dependencies
      ${lib.concatStringsSep "\n" darwinEdges}
      ${lib.concatStringsSep "\n" nixosEdges}

        %% HomeManager module dependencies
      ${lib.concatStringsSep "\n" hmEdges}

      ${secretsSection}
        %% Styling
        classDef host fill:#e1f5fe,stroke:#0288d1,stroke-width:2px
        classDef user fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
        classDef sysMod fill:#e8f5e9,stroke:#388e3c
        classDef hmMod fill:#fff3e0,stroke:#f57c00

        class ${lib.concatStringsSep "," (map (h: sanitize h.host) realHosts)} host
        class ${lib.concatStringsSep "," userNames} user
        class ${lib.concatStringsSep "," (map (n: "d-${sanitize n}") darwinModuleNames)} sysMod
        class ${lib.concatStringsSep "," (map (n: "nixos-${sanitize n}") nixosModuleNames)} sysMod
        class ${lib.concatStringsSep "," (map (n: "hm-${sanitize n}") hmModuleNames)} hmMod
    '';

in
mermaid
