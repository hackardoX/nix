{
  config,
  lib,
  pkgs,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/suites-options/common/default.nix") {
    inherit config lib namespace;
  };

  config = mkIf cfg.enable {
    home = {
      # Silence login messages in shells
      file = {
        ".hushlogin".text = "";
      };

      shellAliases = {
        nixcfg = "code ~/${namespace}/flake.nix";
        ndu = "nix-du -s=200MB | dot -Tsvg > store.svg && open store.svg";
      };
    };

    home.packages =
      with pkgs;
      [
        curl
        fd
        killall
        lsof
        openssh
        tldr
        tree
        unzip
        wget
        wikiman
      ]
      ++ lib.optionals osConfig.${namespace}.tools.homebrew.masEnable [
        mas
      ];

    ${namespace} = {
      programs = {
        terminal = {
          emulators = {
            warp = {
              enable = true;
              default = true;
            };
          };

          shell = {
            zsh = enabled;
            bash = enabled;
          };

          tools = {
            bat = enabled;
            comma = enabled;
            direnv = enabled;
            eza = enabled;
            git = enabled;
            nh = enabled;
            topgrade = enabled;
            zoxide = enabled;
          };
        };
      };

      system.input.enable = pkgs.stdenv.hostPlatform.isDarwin;
    };

    programs = {
      # FIXME: breaks zsh aliases
      # pay-respects =  enabled;
      readline = {
        enable = true;

        extraConfig = ''
          set completion-ignore-case on
        '';
      };
    };
  };
}
