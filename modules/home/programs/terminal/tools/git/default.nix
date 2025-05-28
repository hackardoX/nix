{
  config,
  lib,
  pkgs,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib)
    types
    mkEnableOption
    mkIf
    ;
  inherit (lib.${namespace}) mkOpt enabled;
  inherit (config.${namespace}) user;

  cfg = config.${namespace}.programs.terminal.tools.git;

  ignores = import ./ignores.nix;

  tokenExports =
    lib.optionalString osConfig.${namespace}.security.sops.enable # Bash
      ''
        if [ -f ${config.sops.secrets."github/access-token".path} ]; then
          GITHUB_TOKEN="$(cat ${config.sops.secrets."github/access-token".path})"
          export GITHUB_TOKEN
          GH_TOKEN="$(cat ${config.sops.secrets."github/access-token".path})"
          export GH_TOKEN
        fi
      '';
in
{
  imports = [
    ./shellAliases.nix
    ./shellFunctions.nix
  ];

  options.${namespace}.programs.terminal.tools.git = {
    enable = mkEnableOption "Git";
    includes = mkOpt (types.listOf types.attrs) [ ] "Git includeIf paths and conditions.";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
    signingKey =
      mkOpt types.str "${config.home.homeDirectory}/.ssh/git_signature.pub"
        "The key ID to sign commits with.";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    _1password = lib.mkEnableOption "1Password integration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      git-absorb
      git-crypt
      git-filter-repo
      git-lfs
      # gitflow
      gitleaks
      gitlint
    ];

    programs = {
      git = {
        enable = true;
        package = pkgs.gitFull;

        inherit (cfg) includes userName userEmail;
        inherit (ignores) ignores;

        maintenance.enable = true;

        extraConfig = {
          branch.sort = "-committerdate";

          # credential = {
          #   helper = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin (
          #     getExe' config.programs.git.package "git-credential-osxkeychain"
          #   );

          #   useHttpPath = true;
          # };

          column = {
            ui = "auto";
          };

          core = mkIf config.${namespace}.programs.graphical.editors.vscode.enable {
            editor = "code --wait --new-window";
          };

          fetch = {
            prune = true;
          };

          init = {
            defaultBranch = "main";
          };

          lfs = enabled;

          pull = {
            rebase = true;
          };

          push = {
            autoSetupRemote = true;
            default = "current";
          };

          rerere = {
            enabled = true;
          };

          rebase = {
            autoStash = true;
          };

          safe = {
            directory = [
              "~/${namespace}/"
              "/etc/nixos"
              "/etc/nix-darwin"
            ];
          };

          "url \"ssh://git@\"" = {
            insteadOf = "https://";
          };
        };

        hooks = mkIf (!cfg._1password) {
          prepare-commit-msg = lib.getExe (
            pkgs.writeShellScriptBin "prepare-commit-msg" ''
              echo "Signing off commit"
              ${lib.getExe config.programs.git.package} interpret-trailers --if-exists doNothing --trailer \
                "Signed-off-by: ${cfg.userName} <${cfg.userEmail}>" \
                --in-place "$1"
            ''
          );
        };

        signing = {
          key = cfg.signingKey;
          format = "ssh";
          signer = mkIf cfg._1password (
            lib.optionalString pkgs.stdenv.hostPlatform.isDarwin "${pkgs._1password-gui}/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
          );
          inherit (cfg) signByDefault;
        };
      };

      # Merge helper
      mergiraf = enabled;

      zsh.initContent = tokenExports;
    };

    sops.secrets = lib.mkIf osConfig.${namespace}.security.sops.enable {
      "github/access-token" = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/gh/access-token";
      };
    };
  };
}
