{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    types
    ;
  inherit (lib.${namespace}) mkOpt;

  _1passwordOriginalSocketPath = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  _1passwordSymLinkSocketPath = "${config.home.homeDirectory}/.1password/agent.sock";
  cfg = config.${namespace}.programs.terminal.tools._1password;
in
{
  options.${namespace}.programs.terminal.tools._1password = {
    enable = mkEnableOption "1password";
    enableSshSocket = mkEnableOption "ssh-agent socket";
    plugins = mkOpt (types.listOf types.package) [ ] "1Password shell plugins";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age-plugin-1p
      _1password-cli
      _1password-gui
    ];

    home.sessionVariables = mkIf cfg.enableSshSocket {
      SSH_AUTH_SOCK = "${_1passwordSymLinkSocketPath}";
    };

    programs = {
      _1password-shell-plugins = mkIf (cfg.plugins != [ ]) {
        inherit (cfg) plugins;
        enable = true;
      };

      ssh.extraConfig = mkIf cfg.enableSshSocket ''
        Host *
          AddKeysToAgent yes
          IdentityAgent ${_1passwordSymLinkSocketPath}
          PreferredAuthentications publickey
      '';
    };

    home.file = mkIf cfg.enableSshSocket {
      "${_1passwordSymLinkSocketPath}" = {
        source = config.lib.file.mkOutOfStoreSymlink _1passwordOriginalSocketPath;
      };

      ".config/1Password/ssh/agent.toml".text = ''
        [[ssh-keys]]
        vault = "Development"

        [[ssh-keys]]
        vault = "Private"
      '';
    };
  };
}
