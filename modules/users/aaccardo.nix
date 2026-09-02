{ config, ... }:
{
  flake.meta.users.aaccardo = {
    email = config.flake.lib.fromBase64 "YWFjY2FyZG9AcHJvdG9uLmNoCg==";
    description = "Andrea Accardo";
    name = "aaccardo";
    uid = 502;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyyfmn+7pOkf7UXgWV6BzceLpJk49AT07XgCnnbd323 aaccardo"
    ];

    git = {
      name = "aaccardo";
      email = config.flake.lib.fromBase64 "YWFjY2FyZG9AcHJvdG9uLmNoCg==";
      signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIplaceholder aaccardo@git";
      # TODO: Add an option to setup the password manager to use for git signing
    };
  };

  flake.modules.darwin.aaccardo =
    { pkgs, ... }:
    {
      nix.settings.allowed-users = [ config.flake.meta.users.aaccardo.name ];

      users.users.${config.flake.meta.users.aaccardo.name} = {
        inherit (config.flake.meta.users.aaccardo)
          description
          name
          uid
          ;
        home = "/Users/${config.flake.meta.users.aaccardo.name}";
        shell = pkgs.zsh;
      };

      system.defaults.dock.persistent-apps = [
        "/Applications/Safari.app"
        {
          spacer = {
            small = true;
          };
        }
        "/System/Applications/Proton Mail.app"
        "/System/Applications/Proton Meet.app"
        "/System/Applications/Proton Pass.app"
        "/System/Applications/Proton VPN.app"
        {
          spacer = {
            small = true;
          };
        }
        "/System/Applications/Slack.app"
        {
          spacer = {
            small = true;
          };
        }
        "${pkgs.ghostty-bin}/Applications/Ghostty.app"
        {
          spacer = {
            small = true;
          };
        }
        "/System/Applications/System Settings.app"
        {
          spacer = {
            small = true;
          };
        }
      ];
    };

  flake.modules.homeManager.aaccardo = {
    imports = with config.flake.modules.homeManager; [
      base
      dev
      proton-pass
      shell
      theme
    ];
    home.username = config.flake.meta.users.aaccardo.name;
    home.stateVersion = "24.11";
    home.file = {
      ".ssh/github_authorisation.pub".text = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIplaceholder aaccardo@github.com
      '';
      ".ssh/git_signature.pub".text = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIplaceholder aaccardo@git
      '';
    };
  };
}
