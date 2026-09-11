{ config, ... }:
{
  flake.meta.users.aaccardo = {
    email = config.flake.lib.fromBase64 "YW5kcmVhLmFjY2FyZG9AcHJvdG9uLmNo";
    description = "Andrea Accardo";
    name = "aaccardo";
    uid = 501;
  };

  flake.modules.darwin.aaccardo =
    { pkgs, ... }:
    {
      imports = [ config.flake.modules.darwin.web-browsers ];

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
        "/Applications/Proton Mail.app"
        "/Applications/Proton Meet.app"
        "/Applications/Proton Pass.app"
        "/Applications/ProtonVPN.app"
        {
          spacer = {
            small = true;
          };
        }
        "/Applications/Slack.app"
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
      git
      proton-pass
      shell
      theme
      web-browsers
    ];
    sops.defaultSopsFile = ../../secrets/users/aaccardo.yaml;
    home.username = config.flake.meta.users.aaccardo.name;
    home.stateVersion = "24.11";
  };
}
