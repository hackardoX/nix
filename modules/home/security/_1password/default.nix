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
  cfg = config.${namespace}.security._1password;
in
{
  options.${namespace}.security._1password = {
    enable = mkEnableOption "1password";
    plugins = mkOpt (types.listOf types.package) [ ] "1Password shell plugins";
    sshSocket = mkEnableOption "ssh-agent socket";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        _1password-cli
        _1password-gui
      ];

      sessionVariables = mkIf cfg.sshSocket {
        SSH_AUTH_SOCK = "${_1passwordSymLinkSocketPath}";
      };

      file = mkIf cfg.sshSocket {
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

    programs = {
      _1password-shell-plugins = mkIf (cfg.plugins != [ ]) {
        inherit (cfg) plugins;
        enable = true;
      };

      ssh.extraConfig = mkIf cfg.sshSocket ''
        IdentityAgent ${_1passwordSymLinkSocketPath}
        PreferredAuthentications publickey,keyboard-interactive
      '';
    };
  };
}
