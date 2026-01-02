{ inputs, ... }:
{
  flake.modules.darwin.password-manager = {
    homebrew = {
      masApps = {
        "1Password for Safari" = 1569813296;
      };
    };

    programs = {
      _1password-gui.enable = true;
      _1password.enable = true;
    };
  };

  flake.modules.homeManager.password-manager =
    { config, pkgs, ... }:
    let
      _1passwordOriginalSocketPath = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
      _1passwordSymLinkSocketPath = "${config.home.homeDirectory}/.1password/agent.sock";
    in
    {
      imports = [ inputs.op-shell-plugins.hmModules.default ];
      home = {
        sessionVariables = {
          SSH_AUTH_SOCK = "${_1passwordSymLinkSocketPath}";
        };

        file = {
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
        _1password-shell-plugins = {
          enable = true;
          plugins = with pkgs; [
            gh
            hcloud
            stripe-cli
          ];
        };
      };

      ssh.extraConfig = ''
        IdentityAgent ${_1passwordSymLinkSocketPath}
        PreferredAuthentications publickey,keyboard-interactive
      '';
    };
}
