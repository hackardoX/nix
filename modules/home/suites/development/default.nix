{
  config,
  lib,
  osConfig,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault mkEnableOption;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.development;
in
{
  options.${namespace}.suites.development = {
    enable = mkEnableOption "common development configuration";
    dockerEnable = mkEnableOption "docker development configuration";
    nixEnable = mkEnableOption "nix development configuration";
    sqlEnable = mkEnableOption "sql development configuration";
    aiEnable = mkEnableOption "ai development configuration";
  };

  config = mkIf cfg.enable {
    home = {
      packages =
        with pkgs;
        [
          bat
          bruno
          bruno-cli
          direnv
          eza
          openssh
          vscode
          wget
          zip
          zoxide
        ]
        ++ lib.optionals cfg.nixEnable [
          nh
          nix-bisect
          nix-diff
          nix-fast-build
          nix-health
          nix-index
          nix-output-monitor
          nix-update
          nixpkgs-hammering
          nixpkgs-lint-community
          nixpkgs-review
          nurl
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
          nrl = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2'';
          nrlp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2 --post-result'';
          nup = ''nix-update --commit -u $1'';
          num = ''nix-shell maintainers/scripts/update.nix --argstr maintainer $1'';
          ncs = ''f(){ nix build "nixpkgs#$1" --no-link && nix path-info --recursive --closure-size --human-readable $(nix-build --no-out-link '<nixpkgs>' -A "$1"); }; f'';
          ncsnc = ''f(){ nix build ".#nixosConfigurations.$1.config.system.build.toplevel" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#nixosConfigurations.$1.config.system.build.toplevel.outPath"); }; f'';
          ncsdc = ''f(){ nix build ".#darwinConfigurations.$1.config.system.build.toplevel" --no-link && nix path-info --recursive --closure-size --human-readable $(nix eval --raw ".#darwinConfigurations.$1.config.system.build.toplevel.outPath"); }; f'';
          # NOTE: vim-add 'owner/repo'
          vim-add = ''nix run nixpkgs#vimPluginsUpdater add'';
          # NOTE: vim-update 'plugin-name'
          vim-update = ''nix run nixpkgs#vimPluginsUpdater update'';
          vim-update-all = ''nix run nixpkgs#vimPluginsUpdater -- --github-token=$(echo $GITHUB_TOKEN)'';
          lua-update-all = ''nix run nixpkgs#luarocks-packages-updater -- --github-token=$(echo $GITHUB_TOKEN)'';

          # Home-Manager
          hmd = ''nix build -L .#docs-html && ${
            if pkgs.stdenv.hostPlatform.isDarwin then
              "open -a /Applications/Firefox\\ Developer\\ Edition.app"
            else
              lib.getExe config.programs.firefox.package
          } result/share/doc/home-manager/index.xhtml'';
          hmt = ''f(){ nix-build -j auto --show-trace --pure --option allow-import-from-derivation false tests -A build."$1"; }; f'';
          hmtf = ''f(){ nix build -L --option allow-import-from-derivation false --reference-lock-file flake.lock "./tests#test-$1"; }; f'';
          hmts = ''f(){ nix build -L --option allow-import-from-derivation false --reference-lock-file flake.lock "./tests#test-$1" && nix path-info -rSh ./result; }; f'';
          hmt-repl = ''nix repl --reference-lock-file flake.lock ./tests'';
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
            vscode = mkDefault enabled;
          };
        };

        terminal = {
          tools = {
            act = mkDefault enabled;
            gh = mkDefault enabled;
            jq = mkDefault enabled;
            prisma.enable = mkDefault cfg.sqlEnable;
          };
        };
      };

      services.ollama.enable = mkDefault (cfg.aiEnable && pkgs.stdenv.hostPlatform.isDarwin);
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
