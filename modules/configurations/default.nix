{
  config,
  inputs,
  lib,
  ...
}:
let
  collectImports =
    mod:
    if builtins.isAttrs mod && mod ? imports then
      mod.imports ++ lib.concatMap collectImports mod.imports
    else
      [ mod ];

  findDuplicates = list: lib.filter (x: lib.count (y: x == y) list > 1) (lib.unique list);

  getImportName =
    imp:
    if builtins.isString imp then
      imp
    else if builtins.isPath imp then
      builtins.toString imp
    else if builtins.isAttrs imp && imp ? _file then
      imp._file
    else
      "<anonymous>";

  nixosSystems = lib.flip lib.mapAttrs config.configurations.nixos (
    _name: { module, ... }: lib.nixosSystem { modules = [ module ]; }
  );

  darwinSystems = lib.flip lib.mapAttrs config.configurations.darwin (
    _name: { module, ... }: inputs.darwin.lib.darwinSystem { modules = [ module ]; }
  );
in
{
  options = {
    configurations.nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options.module = lib.mkOption {
            type = lib.types.deferredModule;
          };
        }
      );
    };

    configurations.darwin = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options.module = lib.mkOption {
            type = lib.types.deferredModule;
          };
        }
      );
    };
  };

  config.flake = {
    nixosConfigurations = nixosSystems;
    darwinConfigurations = darwinSystems;

    checks = lib.mkMerge [
      (lib.mkMerge (
        lib.mapAttrsToList (name: nixos: {
          ${nixos.config.nixpkgs.hostPlatform.system} = {
            "configurations/nixos/${name}" = nixos.config.system.build.toplevel;
          };
        }) nixosSystems
      ))

      (lib.mkMerge (
        lib.mapAttrsToList (
          name: nixos:
          let
            module = config.configurations.nixos.${name}.module;
            allImports = collectImports module;
            duplicates = findDuplicates allImports;
            duplicateNames = map getImportName duplicates;
            system = nixos.config.nixpkgs.hostPlatform.system;
          in
          {
            ${system} = {
              "duplicate-imports/nixos/${name}" =
                if duplicates != [ ] then
                  inputs.nixpkgs.legacyPackages.${system}.runCommand "duplicate-imports-nixos-${name}" { } (
                    ''
                      echo "Host '${name}' has ${toString (builtins.length duplicates)} duplicate module import(s):"
                    ''
                    + lib.concatMapStrings (n: ''
                      echo "  - ${n}"
                    '') duplicateNames
                    + ''
                      exit 1
                    ''
                  )
                else
                  inputs.nixpkgs.legacyPackages.${system}.runCommand "duplicate-imports-ok-nixos-${name}" { }
                    "touch $out";
            };
          }
        ) nixosSystems
      ))

      (lib.mkMerge (
        lib.mapAttrsToList (name: darwin: {
          ${darwin.config.nixpkgs.hostPlatform.system} = {
            "configurations/darwin/${name}" = darwin.config.system.build.toplevel;
          };
        }) darwinSystems
      ))

      (lib.mkMerge (
        lib.mapAttrsToList (
          name: darwin:
          let
            module = config.configurations.darwin.${name}.module;
            allImports = collectImports module;
            duplicates = findDuplicates allImports;
            duplicateNames = map getImportName duplicates;
            system = darwin.config.nixpkgs.hostPlatform.system;
          in
          {
            ${system} = {
              "duplicate-imports/darwin/${name}" =
                if duplicates != [ ] then
                  inputs.nixpkgs.legacyPackages.${system}.runCommand "duplicate-imports-darwin-${name}" { } (
                    ''
                      echo "Host '${name}' has ${toString (builtins.length duplicates)} duplicate module import(s):"
                    ''
                    + lib.concatMapStrings (n: ''
                      echo "  - ${n}"
                    '') duplicateNames
                    + ''
                      exit 1
                    ''
                  )
                else
                  inputs.nixpkgs.legacyPackages.${system}.runCommand "duplicate-imports-ok-darwin-${name}" { }
                    "touch $out";
            };
          }
        ) darwinSystems
      ))
    ];
  };
}
