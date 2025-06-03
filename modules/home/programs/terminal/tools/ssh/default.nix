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

  user = config.${namespace}.user.name;
  user-id = builtins.toString user.uid;

  other-hosts = lib.filterAttrs (_key: host: (host.config.${namespace}.user.name or null) != null) (
    inputs.self.darwinConfigurations or { }
  );

  github-host-config = {
    "github.com" = {
      forwardAgent = false;
      identitiesOnly = true;
      identityFile = "/Users/${user}/.ssh/github.pub";
    };
  };

  other-hosts-config = lib.foldl' (
    acc: name:
    let
      remote = other-hosts.${name};
      remote-user-name = remote.config.${namespace}.user.name;
      remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;
    in
    acc
    // {
      ${name} = {
        hostname = "${name}.local";
        user = remote-user-name;
        forwardAgent = true;
        identityFile = "/Users/${user}/.ssh/${name}.pub";
        inherit (cfg) port;
        remoteForwards =
          lib.optionals (config.services.gpg-agent.enable && remote.config.services.gpg-agent.enable)
            [
              "/run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra"
              "/run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh"
            ];
      };
    }
  ) { } (builtins.attrNames other-hosts);
in
{
  options.${namespace}.programs.terminal.tools.ssh = with types; {
    enable = lib.mkEnableOption "ssh support";
    authorizedKeys = mkOpt (listOf str) [ ] "The public keys to apply.";
    allowedSigners = mkOpt (listOf str) [ ] "The allowed signers to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 22 "The port to listen on.";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      serverAliveInterval = 60;
      controlMaster = "auto";
      controlPersist = "30m";

      addKeysToAgent = "yes";
      forwardAgent = true;
      matchBlocks = github-host-config // other-hosts-config;

      extraConfig =
        ''
          StreamLocalBindUnlink yes
        ''
        + lib.optionalString (cfg.extraConfig != "") cfg.extraConfig;
    };

    home = {
      shellAliases =
        foldl (aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; })
          {
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
          }
          (builtins.attrNames other-hosts);

      file = {
        ".ssh/authorized_keys".text = builtins.concatStringsSep "\n" cfg.authorizedKeys;
        ".ssh/allowed_signers".text = builtins.concatStringsSep "\n" cfg.allowedSigners;
      };
    };
  };
}
