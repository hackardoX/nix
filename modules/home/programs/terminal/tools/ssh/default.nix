{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib)
    foldl
    getExe'
    mkIf
    types
    ;
  inherit (lib.${namespace}) mkOpt mkOpt';
  inherit (inputs) home-manager;

  cfg = config.${namespace}.programs.terminal.tools.ssh;
in
{
  options.${namespace}.programs.terminal.tools.ssh = with types; {
    enable = lib.mkEnableOption "ssh support";
    authorizedKeys = mkOpt (listOf types.str) [ ] "The public keys to apply.";
    allowedSigners = mkOpt (listOf types.str) [ ] "The allowed signers to apply.";
    knownHosts = mkOpt (listOf types.str) [ ] "Known hosts.";
    extraConfig = mkOpt types.str "" "Extra configuration to apply.";
    hosts = mkOpt (types.attrsOf (
      types.submodule {
        options = {
          hostname = mkOpt' types.str "The hostname to connect to.";
          user = mkOpt' types.str "The user to connect as.";
          forwardAgent = mkOpt' types.bool "Whether to forward the authentication agent.";
          identitiesOnly = mkOpt' types.bool "Whether to use only the specified identities.";
          identityFile = mkOpt' types.str "The identity file to use.";
          port = mkOpt' types.int "The port to connect to.";
        };
      }
    )) { } "Additional SSH hosts configuration.";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          addKeysToAgent = "yes";
          controlMaster = "auto";
          controlPersist = "30m";
          forwardAgent = true;
          hashKnownHosts = true;
          serverAliveInterval = 60;
        };
      }
      // cfg.hosts;
      extraConfig = ''
        StreamLocalBindUnlink yes
      ''
      + lib.optionalString (cfg.extraConfig != "") cfg.extraConfig;
    };

    home = {
      shellAliases = foldl (aliases: system: aliases // { "ssh-${system}" = "ssh ${system}"; }) {
        ssh-list-perm-user = # Bash
          ''find ~/.ssh -exec stat -c "%a %n" {} \;'';

        ssh-perm-user = lib.concatStrings [
          # Bash
          ''${getExe' pkgs.findutils "find"} ~/.ssh -type f -exec chmod 600 {} \;;''
          # Bash
          ''${getExe' pkgs.findutils "find"} ~/.ssh -type d -exec chmod 700 {} \;;''
          # Bash
          ''${getExe' pkgs.findutils "find"} ~/.ssh -type f -name "*.pub" -exec chmod 644 {} \;''
        ];

        ssh-list-perm-system = # Bash
          ''sudo find /etc/ssh -exec stat -c "%a %n" {} \;'';

        ssh-perm-system = lib.concatStrings [
          # Bash
          ''sudo ${getExe' pkgs.findutils "find"} /etc/ssh -type f -exec chmod 600 {} \;;''
          # Bash
          ''sudo ${getExe' pkgs.findutils "find"} /etc/ssh -type d -exec chmod 700 {} \;;''
          # Bash
          ''sudo ${getExe' pkgs.findutils "find"} /etc/ssh -type f -name "*.pub" -exec chmod 644 {} \;''
        ];
      } (builtins.attrNames cfg.hosts);

      file = {
        ".ssh/authorized_keys" = mkIf (cfg.authorizedKeys != [ ]) {
          text = builtins.concatStringsSep "\n" cfg.authorizedKeys;
        };
        ".ssh/allowed_signers" = mkIf (cfg.allowedSigners != [ ]) {
          text = builtins.concatStringsSep "\n" cfg.allowedSigners;
        };
      };

      activation.generateKnownHosts = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        PATH=${pkgs.openssh}/bin:$PATH
        known_hosts_file="$HOME/.ssh/known_hosts"
        temp_file="$(mktemp)"

        # Ensure .ssh directory exists
        mkdir -p "$HOME/.ssh"

        # Clear temp file
        > "$temp_file"

        # Process each hostname
        ${lib.concatMapStringsSep "\n" (hostname: ''
          echo "Scanning ${hostname}..."
          ssh-keyscan -H "${hostname}" >> "$temp_file" || echo "Failed to scan ${hostname}" >&2
        '') cfg.knownHosts}

        # Remove empty lines and duplicates, then update known_hosts
        if [[ -s "$temp_file" ]]; then
          grep -v '^[[:space:]]*$' "$temp_file" | sort -u > "$known_hosts_file"
          chmod 644 "$known_hosts_file"
          echo "Updated SSH known_hosts with entries from ${toString (lib.length cfg.knownHosts)} hostnames"
        else
          echo "No SSH keys were successfully scanned"
        fi

        # Cleanup
        rm "$temp_file"
      '';
    };
  };
}
