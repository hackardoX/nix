{
  config,
  lib,
  pkgs,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  options.${namespace}.suites.common = {
    enable = lib.mkEnableOption "common configuration";
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
        tldr
        unzip
        wget
        tree
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
              enable = mkDefault true;
              default = mkDefault true;
            };
          };

          shell = {
            zsh = mkDefault enabled;
          };

          tools = {
            bat = mkDefault enabled;
            comma = mkDefault enabled;
            direnv = mkDefault enabled;
            eza = mkDefault enabled;
            git = mkDefault enabled;
            nh = mkDefault enabled;
            ssh = mkDefault enabled;
            topgrade = mkDefault enabled;
            zoxide = mkDefault enabled;
          };
        };
      };

      services = { };

      system.input.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isDarwin;
    };

    programs = {
      # FIXME: breaks zsh aliases
      # pay-respects = mkDefault enabled;
      readline = {
        enable = mkDefault true;

        extraConfig = ''
          set completion-ignore-case on
        '';
      };
    };
  };
}
