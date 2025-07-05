{
  config,
  lib,
  osConfig,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    ;
  inherit (lib.${namespace}) enabled disabled;

  cfg = config.${namespace}.suites.development;
in
{
  options =
    import (lib.snowfall.fs.get-file "modules/shared/suites-options/development/default.nix")
      {
        inherit lib namespace;
      };

  config = mkIf cfg.enable {
    home = {
      packages =
        with pkgs;
        [
          bat
          # TODO: this is blocking the darwin build. Need to figure out why.
          # bruno
          # bruno-cli
          direnv
          eza
          vscode
          wget
          zip
          zoxide
        ]
        ++ lib.optionals cfg.nixEnable [
          nh
          nixd
          nix-bisect
          nix-diff
          nix-fast-build
          nixfmt-rfc-style
          nix-health
          nix-index
          nix-output-monitor
          nix-update
          nixpkgs-hammering
          nixpkgs-lint-community
          nixpkgs-review
          nurl
          treefmt
          pkgs.${namespace}.treefmt-nix
        ]
        ++ lib.optionals osConfig.${namespace}.tools.homebrew.masEnable [
          mas
        ];

      shellAliases =
        mkIf cfg.nixEnable {
          # Nixpkgs
          prefetch-sri = "nix store prefetch-file $1";
          nrh = ''${lib.getExe pkgs.nixpkgs-review} rev HEAD'';
          nra = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all"'';
          nrap = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all" --post-result --num-parallel-evals 4'';
          nrapa = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all" --post-result --num-parallel-evals 4 --approve-pr'';
          nrd = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin" --num-parallel-evals 2'';
          nrdp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin" --num-parallel-evals 2 --post-result'';
          nup = ''nix-update --commit -u $1'';
          num = ''nix-shell maintainers/scripts/update.nix --argstr maintainer $1'';
          ncs = ''f(){ nix build "nixpkgs#$1" --no-link && nix path-info --recursive --closure-size --human-readable $(nix-build --no-out-link '<nixpkgs>' -A "$1"); }; f'';
          ncsdc = ''f(){ nix build ".#darwinConfigurations.$1.config.system.build.toplevel" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#darwinConfigurations.$1.config.system.build.toplevel.outPath"); }; f'';

          # Home-Manager
          hmd = ''nix build -L .#docs-html ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin "&& open result/share/doc/home-manager/index.xhtml"}'';
          hmt = ''f(){ nix-build -j auto --show-trace --pure --option allow-import-from-derivation false tests -A build."$1"; }; f'';
          hmtf = ''f(){ nix build -L --option allow-import-from-derivation false --reference-lock-file flake.lock "./tests#test-$1"; }; f'';
          hmts = ''f(){ nix build -L --option allow-import-from-derivation false --reference-lock-file flake.lock "./tests#test-$1" && nix path-info -rSh ./result; }; f'';
          hmt-repl = ''nix repl --reference-lock-file flake.lock ./tests'';

          # Kamal
          kamal = ''f() { [[ " $* " =~ ( -c|--config-file(=| ) ) ]] && command kamal "$@" || command kamal "$@" --config-file ./.kamal/deploy.yml; }; f'';
        }
        // { };
    };

    programs = {
      # zsh.initContent = tokenExports;
    };

    ${namespace} = {
      programs = {
        graphical = {
          editors = {
            vscode = enabled;
          };
        };

        terminal = {
          tools = {
            _1password = {
              plugins = with pkgs; [
                gh
                hcloud
              ];
            };
            act = enabled;
            gh = disabled;
            git = {
              enable = true;
              includes = [ ];
              signByDefault = true;
              signingKey = "${config.home.homeDirectory}/.ssh/git_signature.pub";
              userName = cfg.git.user;
              userEmail = cfg.git.email;
              _1password = config.${namespace}.programs.terminal.tools._1password.enable;
            };
            jq = enabled;
            # jujutsu = enabled;
            prisma.enable = cfg.sqlEnable;
            ssh = {
              enable = true;
              inherit (cfg.ssh) allowedSigners;
              inherit (cfg.ssh) hosts;
            };
          };
        };

        containerization = {
          podman = {
            enable = cfg.containerization.enable && builtins.elem "podman" cfg.containerization.variants;
            rosetta = config.${namespace}.suites.common.rosetta.enable;
            aliasDocker = true;
          };
          docker = {
            enable = cfg.containerization.enable && builtins.elem "docker" cfg.containerization.variants;
          };
        };
      };

      services.ollama.enable = cfg.aiEnable && pkgs.stdenv.hostPlatform.isDarwin;
    };

    # sops.secrets = lib.mkIf osConfig.${namespace}.security.sops.enable {
    #   ANTHROPIC_API_KEY = {
    #     sopsFile = lib.snowfall.fs.get-file "secrets/CORE/default.yaml";
    #     path = "${config.home.homeDirectory}/.ANTHROPIC_API_KEY";
    #   };
    #   AZURE_OPENAI_API_KEY = {
    #     sopsFile = lib.snowfall.fs.get-file "secrets/CORE/default.yaml";
    #     path = "${config.home.homeDirectory}/.AZURE_OPENAI_API_KEY";
    #   };
    #   OPENAI_API_KEY = {
    #     sopsFile = lib.snowfall.fs.get-file "secrets/CORE/default.yaml";
    #     path = "${config.home.homeDirectory}/.OPENAI_API_KEY";
    #   };
    # };
  };
}
