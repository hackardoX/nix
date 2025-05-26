{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
  cfg = config.${namespace}.user;
in
{
  aaccardo = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    programs = {
      terminal = {
        tools = {
          ssh = enabled;
        };
      };
    };

    services = {
      sops = {
        enable = false;
        defaultSopsFile = lib.snowfall.fs.get-file "secrets/${cfg.name}/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    suites = {
      common = enabled;
      development = {
        enable = true;
        aiEnable = true;
        dockerEnable = true;
        nixEnable = true;
        sqlEnable = true;
      };
      music = enabled;
      networking = enabled;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "24.11";
}
