{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionalString;

  cfg = config.${namespace}.programs.terminal.tools._1password;
in
{
  options.${namespace}.programs.terminal.tools._1password = {
    enable = mkEnableOption "1password";
    enableSshSocket = mkEnableOption "ssh-agent socket";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age-plugin-1p
      _1password-cli
      _1password-gui
    ];

    programs = {
      ssh.extraConfig = optionalString cfg.enableSshSocket ''
        Host *
          AddKeysToAgent yes
          IdentityAgent ~/.1password/agent.sock
      '';
    };
  };
}
