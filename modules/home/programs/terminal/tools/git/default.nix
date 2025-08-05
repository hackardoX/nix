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
    mkOption
    ;
  inherit (lib.${namespace}) mkOpt enabled;
  inherit (config.${namespace}) user;

  cfg = config.${namespace}.programs.terminal.tools.git;

  ignores = import ./ignores.nix;

  tokenExports =
    lib.optionalString (config.${namespace}.security.opnix.enable or false) # Bash
      ''
        if [ -f "${config.programs.onepassword-secrets.secretPaths.githubAccessToken}" ]; then
          GITHUB_TOKEN="$(cat ${config.programs.onepassword-secrets.secretPaths.githubAccessToken})"
          GH_TOKEN="$(cat ${config.programs.onepassword-secrets.secretPaths.githubAccessToken})"
          export GITHUB_TOKEN
          export GH_TOKEN
        fi
      ''
    +
      lib.optionalString osConfig.${namespace}.security.sops.enable # Bash
        ''
          if [ -f ${config.sops.secrets.githubAccessToken.path} ]; then
            GITHUB_TOKEN="$(cat ${config.sops.secrets.githubAccessToken.path})"
            export GITHUB_TOKEN
            GH_TOKEN="$(cat ${config.sops.secrets.githubAccessToken.path})"
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
    signingKey = mkOption {
      type = types.str;
      description = "The key ID to sign commits with.";
      example = "${config.home.homeDirectory}/.ssh/git_signature.pub";
      default = null;
    };
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    _1password = lib.mkEnableOption "1Password integration";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.signByDefault && cfg.signingKey != null;
        message = "Git signing key must be set.";
      }
    ];

    home.packages = with pkgs; [
      git-absorb
      git-crypt
      git-filter-repo
      git-lfs
      # gitflow
      gitleaks
    ];

    programs = {
      git = {
        enable = true;
        package = pkgs.git;

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

    ${namespace}.security.opnix.secrets = {
      githubAuthorisation = {
        path = ".ssh/github_authorisation.pub";
        reference = "op://Development/Github Authorisation/public key";
        group = "staff";
      };
      gitSignature = {
        path = ".ssh/git_signature.pub";
        reference = "op://Development/Git Signature/public key";
        group = "staff";
      };
      githubAccessToken = {
        path = ".config/gh/access-token";
        reference = "op://Development/GitHub Personal Access Token/token";
        group = "staff";
      };
    };

    sops.secrets = lib.mkIf osConfig.${namespace}.security.sops.enable {
      githubAuthorisation = {
        sopsFile = lib.snowfall.fs.get-file "secrets/${user}.yaml";
        path = "${config.home.homeDirectory}/.ssh/github_authorisation.pub";
      };
      gitSignature = {
        sopsFile = lib.snowfall.fs.get-file "secrets/${user}.yaml";
        path = "${config.home.homeDirectory}/.ssh/git_signature.pub";
      };
      githubAccessToken = {
        sopsFile = lib.snowfall.fs.get-file "secrets/${user}.yaml";
        path = "${config.home.homeDirectory}/.config/gh/access-token";
      };
    };
  };
}
