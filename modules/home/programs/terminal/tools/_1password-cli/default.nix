{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionalString;

  cfg = config.${namespace}.programs.terminal.tools._1password-cli;
in
{
  options.${namespace}.programs.terminal.tools._1password-cli = {
    enable = mkEnableOption "1password-cli";
    enableSshSocket = mkEnableOption "ssh-agent socket";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age-plugin-1p
      _1password-cli
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
