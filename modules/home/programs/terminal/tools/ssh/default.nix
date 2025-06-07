{
  config,
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

  cfg = config.${namespace}.programs.terminal.tools.ssh;
in
{
  options.${namespace}.programs.terminal.tools.ssh = with types; {
    enable = lib.mkEnableOption "ssh support";
    authorizedKeys = mkOpt (listOf types.str) [ ] "The public keys to apply.";
    allowedSigners = mkOpt (listOf types.str) [ ] "The allowed signers to apply.";
    knownHosts = mkOpt (listOf types.str) [ ] "The known hosts to apply.";
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

      serverAliveInterval = 60;
      controlMaster = "auto";
      controlPersist = "30m";

      addKeysToAgent = "yes";
      forwardAgent = true;
      matchBlocks = cfg.hosts;
      hashKnownHosts = true;

      extraConfig =
        ''
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
        ".ssh/known_hosts" = mkIf (cfg.knownHosts != [ ]) {
          text = builtins.concatStringsSep "\n" cfg.knownHosts;
        };
      };
    };
  };
}
