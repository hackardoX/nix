{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.editors.vscode;
in
{
  options.${namespace}.programs.graphical.editors.vscode = {
    enable = mkEnableOption "Whether or not to enable vscode";
    declarativeConfig = mkBoolOpt true "Whether or not to enable declarative vscode configuration";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".vscode/argv.json" = {
        text = builtins.toJSON {
          "enable-crash-reporter" = true;
          "crash-reporter-id" = "b2dcae93-0bb4-4117-9a61-39aa3966e993";
        };
      };
    };

    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

      profiles =
        let
          commonExtensions =
            with pkgs.vscode-marketplace;
            [
              adpyke.codesnap
              arrterian.nix-env-selector
              catppuccin.catppuccin-vsc
              catppuccin.catppuccin-vsc-icons
              christian-kohler.path-intellisense
              formulahendry.auto-close-tag
              formulahendry.auto-rename-tag
              github.vscode-github-actions
              github.vscode-pull-request-github
              gruntfuggly.todo-tree
              irongeek.vscode-env
              jnoortheen.nix-ide
              mkhl.direnv
              ms-vscode-remote.remote-ssh
              ms-vsliveshare.vsliveshare
              usernamehw.errorlens
              yy0931.gitconfig-lsp
              yzhang.markdown-all-in-one
            ]
            ++ lib.optionals config.${namespace}.suites.development.dockerEnable [
              ms-azuretools.vscode-docker
              ms-vscode-remote.remote-containers
            ]
            ++ lib.optionals config.${namespace}.suites.development.aiEnable [
              continue.continue
            ];
          commonSettings = {
            # Color theme
            "workbench.colorTheme" = lib.mkDefault "Catppuccin Macchiato";
            "catppuccin.accentColor" = lib.mkDefault "mauve";
            "workbench.iconTheme" = "vscode-icons";

            # TODO: Handle font config with stylix
            # Font family
            "editor.fontFamily" =
              lib.mkForce "MonaspaceArgon, Monaspace Argon, CascadiaCode,Consolas, monospace,Hack Nerd Font";
            "editor.codeLensFontFamily" =
              lib.mkForce "MonaspaceNeon, Monaspace Neon, Liga SFMono Nerd Font, CascadiaCode,Consolas, 'Courier New', monospace,Hack Nerd Font";
            "editor.inlayHints.fontFamily" = lib.mkForce "MonaspaceKrypton, Monaspace Krypton";
            "debug.console.fontFamily" = lib.mkForce "MonaspaceKrypton, Monaspace Krypton";
            "scm.inputFontFamily" = lib.mkForce "MonaspaceRadon, Monaspace Radon";
            "notebook.output.fontFamily" = lib.mkForce "MonaspaceRadon, Monapsace Radon";
            "chat.editor.fontFamily" = lib.mkForce "MonaspaceArgon, Monaspace Argon";
            "markdown.preview.fontFamily" =
              lib.mkForce "MonaspaceXenon, Monaspace Xenon; -apple-system, BlinkMacSystemFont, 'Segoe WPC', 'Segoe UI', system-ui, 'Ubuntu', 'Droid Sans', sans-serif";
            "terminal.integrated.fontFamily" =
              lib.mkForce "MonaspaceKrypton, Monaspace Krypton, JetBrainsMono Nerd Font Mono";

            # Git settings
            "git.allowForcePush" = true;
            "git.autofetch" = true;
            "git.blame.editorDecoration.enabled" = true;
            "git.confirmSync" = false;
            "git.enableSmartCommit" = true;
            "git.openRepositoryInParentFolders" = "always";
            "gitlens.gitCommands.skipConfirmations" = [
              "fetch:command"
              "stash-push:command"
              "switch:command"
              "branch-create:command"
            ];

            # Editor
            "editor.bracketPairColorization.enabled" = true;
            "editor.fontLigatures" =
              "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08', 'ss09', 'ss10', 'dlig', 'liga'";
            "editor.fontSize" = lib.mkDefault 12;
            "editor.formatOnPaste" = true;
            "editor.formatOnSave" = true;
            "editor.formatOnType" = false;
            "editor.guides.bracketPairs" = true;
            "editor.guides.indentation" = true;
            "editor.inlineSuggest.enabled" = true;
            "editor.minimap.enabled" = false;
            "editor.minimap.renderCharacters" = false;
            "editor.overviewRulerBorder" = false;
            "editor.renderLineHighlight" = "all";
            "editor.smoothScrolling" = true;
            "editor.suggestSelection" = "first";

            # Terminal
            "terminal.integrated.automationShell.linux" = "nix-shell";
            "terminal.integrated.cursorBlinking" = true;
            "terminal.integrated.defaultProfile.linux" = "zsh";
            "terminal.integrated.enableBell" = false;
            "terminal.integrated.gpuAcceleration" = "on";

            # Nix
            "nixEnvSelector.suggestion" = true;
            "nixEnvSelector.useFlakes" = true;

            # Workbench
            "workbench.editor.tabCloseButton" = "left";
            "workbench.fontAliasing" = "antialiased";
            "workbench.list.smoothScrolling" = true;
            "workbench.panel.defaultLocation" = "right";
            "workbench.startupEditor" = "none";

            # Miscellaneous
            "breadcrumbs.enabled" = true;
            "explorer.confirmDelete" = false;
            "files.trimTrailingWhitespace" = true;
            "javascript.updateImportsOnFileMove.enabled" = "always";
            "security.workspace.trust.enabled" = false;
            "todo-tree.filtering.includeHiddenFiles" = true;
            "typescript.updateImportsOnFileMove.enabled" = "always";
            "vsicons.dontShowNewVersionMessage" = true;
            "window.menuBarVisibility" = "toggle";
            "window.nativeTabs" = true;
            "window.restoreWindows" = "all";
            "window.titleBarStyle" = "custom";

            # LSP
            "C_Cpp.intelliSenseEngine" = "disabled";

            # Formatters
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "[cpp]" = {
              "editor.defaultFormatter" = "xaver.clang-format";
            };
            "[csharp]" = {
              "editor.defaultFormatter" = "ms-dotnettools.csharp";
            };
            "[dockerfile]" = mkIf config.${namespace}.suites.development.dockerEnable {
              "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
            };
            "[gitconfig]" = {
              "editor.defaultFormatter" = "yy0931.gitconfig-lsp";
            };
            "[html]" = {
              "editor.defaultFormatter" = "vscode.html-language-features";
            };
            "[javascript]" = {
              "editor.defaultFormatter" = "vscode.typescript-language-features";
            };
            "[json]" = {
              "editor.defaultFormatter" = "vscode.json-language-features";
            };
            "[lua]" = {
              "editor.defaultFormatter" = "yinfei.luahelper";
            };
            "[shellscript]" = {
              "editor.defaultFormatter" = "foxundermoon.shell-format";
            };
            "[xml]" = {
              "editor.defaultFormatter" = "redhat.vscode-xml";
            };
          };
        in
        {
          default = {
            extensions = [ ];
            enableUpdateCheck = lib.mkIf cfg.declarativeConfig false;
            enableExtensionUpdateCheck = lib.mkIf cfg.declarativeConfig false;
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
          };
          C = {
            extensions =
              with pkgs.vscode-marketplace;
              commonExtensions
              ++ [
                xaver.clang-format
                llvm-vs-code-extensions.vscode-clangd
              ];
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
          };
          Java = {
            extensions =
              with pkgs.vscode-marketplace;
              commonExtensions
              ++ [
                vscjava.vscode-java-pack
              ];
            userSettings = lib.mkIf cfg.declarativeConfig (
              commonSettings
              // {
                # LSP
                "java.jdt.ls.java.home" = "${pkgs.jdk24}/lib/openjdk";
                "java.configuration.runtimes" = [
                  "${pkgs.jdk8}/lib/openjdk"
                  "${pkgs.jdk24}/lib/openjdk"
                ];
                "redhat.telemetry.enabled" = false;

                # Formatters
                "[java]" = {
                  "editor.defaultFormatter" = "redhat.java";
                };

                # Custom file associations
                "files.associations" = {
                  "*.avsc" = "json";
                };
              }
            );
          };
          NextJS = {
            extensions =
              with pkgs.vscode-marketplace;
              commonExtensions
              ++ [
                biomejs.biome
                dbaeumer.vscode-eslint
                ecmel.vscode-html-css
                wix.vscode-import-cost
                orta.vscode-jest
                rvest.vs-code-prettier-eslint
                richie5um2.vscode-sort-json
                bradlc.vscode-tailwindcss
              ];
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
          };
          Editor = {
            extensions = commonExtensions;
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
          };
          Python = {
            extensions =
              with pkgs.vscode-marketplace;
              commonExtensions
              ++ [
                ms-python.python
                ms-toolsai.jupyter
                njpwerner.autodocstring
                charliermarsh.ruff
              ];
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
          };
          Rust = {
            extensions =
              with pkgs.vscode-marketplace;
              commonExtensions
              ++ [
                rust-lang.rust-analyzer
              ];
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
          };
        };
    };
  };
}
