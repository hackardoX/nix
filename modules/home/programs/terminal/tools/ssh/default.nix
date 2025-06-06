{
  config,
  lib,
  inputs,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe'
    types
    mkIf
    foldl
    ;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.programs.terminal.tools.ssh;

  hosts-config = import ./hosts.nix {
    inherit
      config
      lib
      inputs
      namespace
      ;
  };
in
{
  options.${namespace}.programs.terminal.tools.ssh = with types; {
    enable = lib.mkEnableOption "ssh support";
    authorizedKeys = mkOpt (listOf str) [ ] "The public keys to apply.";
    allowedSigners = mkOpt (listOf str) [ ] "The allowed signers to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      serverAliveInterval = 60;
      controlMaster = "auto";
      controlPersist = "30m";

      addKeysToAgent = "yes";
      forwardAgent = true;
      matchBlocks = hosts-config;
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
      } (builtins.attrNames hosts-config);

      file = {
        ".ssh/authorized_keys".text = builtins.concatStringsSep "\n" cfg.authorizedKeys;
        ".ssh/allowed_signers".text = builtins.concatStringsSep "\n" cfg.allowedSigners;
        # ".ssh/known_hosts".text = builtins.concatStringsSep "\n" cfg.knownHosts;
      };
    };
  };
}
