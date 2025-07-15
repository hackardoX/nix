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
  imports = [
    ./continue.dev.nix
  ];

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
          commonExtensions = pkgs.nix4vscode.forVscode (
            [
              "1password.op-vscode"
              "adpyke.codesnap"
              "arrterian.nix-env-selector"
              "catppuccin.catppuccin-vsc"
              "catppuccin.catppuccin-vsc-icons"
              "christian-kohler.path-intellisense"
              "esbenp.prettier-vscode"
              "formulahendry.auto-close-tag"
              "formulahendry.auto-rename-tag"
              "foxundermoon.shell-format"
              "github.vscode-github-actions"
              "github.vscode-pull-request-github"
              "gruntfuggly.todo-tree"
              "ibecker.treefmt-vscode"
              "irongeek.vscode-env"
              "jnoortheen.nix-ide"
              "mkhl.direnv"
              "ms-azuretools.vscode-docker"
              "ms-vscode-remote.remote-ssh"
              "ms-vsliveshare.vsliveshare"
              "redhat.vscode-xml"
              "usernamehw.errorlens"
              "yinfei.luahelper"
              "yy0931.gitconfig-lsp"
              "yzhang.markdown-all-in-one"
            ]
            ++ lib.optionals config.${namespace}.suites.development.containerization.enable [
              "ms-azuretools.vscode-docker"
              "ms-vscode-remote.remote-containers"
            ]
            ++ lib.optionals config.${namespace}.suites.development.aiEnable [
              "continue.continue"
            ]
          );
          commonSettings = {
            # Color theme
            "workbench.colorTheme" = lib.mkDefault "Catppuccin Macchiato";
            "catppuccin.accentColor" = lib.mkDefault "mauve";
            "workbench.iconTheme" = lib.mkDefault "catppuccin-macchiato";

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
            "editor.tabSize" = 2;
            "editor.wordWrap" = "on";

            # Terminal
            "terminal.integrated.automationShell.linux" = "nix-shell";
            "terminal.integrated.cursorBlinking" = true;
            "terminal.integrated.defaultProfile.linux" = "zsh";
            "terminal.integrated.enableVisualBell" = false;
            "terminal.integrated.gpuAcceleration" = "on";

            # Nix
            "nixEnvSelector.suggestion" = true;
            "nixEnvSelector.useFlakes" = true;
            "nix.enableLanguageServer" = true;
            "nix.formatterPath" = "nixfmt";
            "nix.serverPath" = "nixd";
            "nix.serverSettings" = {
              "nixd" = {
                "formatting" = {
                  "command" = [ "nixfmt" ];
                };
              };
            };

            # Workbench
            "workbench.editor.tabCloseButton" = "left";
            "workbench.fontAliasing" = "antialiased";
            "workbench.list.smoothScrolling" = true;
            "workbench.panel.defaultLocation" = "right";
            "workbench.startupEditor" = "none";
            "workbench.editor.tabActionLocation" = "left";

            # Search
            "search.exclude" = {
              "**/.direnv/**" = true;
              "**/node_modules/**" = true;
            };

            # Miscellaneous
            "accessibility.signals.terminalBell" = {
              "sound" = "off";
            };
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
            "treefmt.command" = "treefmt-nix";
            "editor.defaultFormatter" = "ibecker.treefmt-vscode";

            # Use treefmt for all files
            # "[cpp]" = {
            #   "editor.defaultFormatter" = "xaver.clang-format";
            # };
            # "[csharp]" = {
            #   "editor.defaultFormatter" = "ms-dotnettools.csharp";
            # };
            # "[dockerfile]" = mkIf config.${namespace}.suites.development.containerization.enable {
            #   "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
            # };
            # "[gitconfig]" = {
            #   "editor.defaultFormatter" = "yy0931.gitconfig-lsp";
            # };
            # "[html]" = {
            #   "editor.defaultFormatter" = "vscode.html-language-features";
            # };
            # "[javascript]" = {
            #   "editor.defaultFormatter" = "vscode.typescript-language-features";
            # };
            # "[json]" = {
            #   "editor.defaultFormatter" = "vscode.json-language-features";
            # };
            # "[typescriptreact]" = {
            #   "editor.defaultFormatter" = "esbenp.prettier-vscode";
            # };
            # "[lua]" = {
            #   "editor.defaultFormatter" = "yinfei.luahelper";
            # };
            # "[nix]" = {
            #   "editor.defaultFormatter" = "jnoortheen.nix-ide";
            # };
            # "[shellscript]" = {
            #   "editor.defaultFormatter" = "foxundermoon.shell-format";
            # };
            # "[xml]" = {
            #   "editor.defaultFormatter" = "redhat.vscode-xml";
            # };

            # AI
            "continue.telemetryEnabled" = mkIf config.${namespace}.suites.development.aiEnable false;
          };
          commonKeyBindings = [
            {
              key = "ctrl+cmd+i";
              command = "";
              when = "!chatSetupHidden";
            }
            {
              key = "shift+cmd+i";
              command = "";
              when = "config.chat.agent.enabled && !chatSetupHidden";
            }
          ];
        in
        {
          default = {
            extensions = commonExtensions;
            enableUpdateCheck = lib.mkIf cfg.declarativeConfig false;
            enableExtensionUpdateCheck = lib.mkIf cfg.declarativeConfig false;
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
          };
          C = {
            extensions =
              commonExtensions
              ++ pkgs.nix4vscode.forVscode [
                "xaver.clang-format"
                "llvm-vs-code-extensions.vscode-clangd"
              ];
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
            keybindings = lib.mkIf cfg.declarativeConfig commonKeyBindings;
          };
          Java = {
            extensions =
              commonExtensions
              ++ pkgs.nix4vscode.forVscode [
                "vscjava.vscode-java-pack"
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
            keybindings = lib.mkIf cfg.declarativeConfig commonKeyBindings;
          };
          Javascript = {
            extensions =
              commonExtensions
              ++ pkgs.nix4vscode.forVscode [
                "biomejs.biome"
                "dbaeumer.vscode-eslint"
                "ecmel.vscode-html-css"
                "wix.vscode-import-cost"
                "orta.vscode-jest"
                "rvest.vs-code-prettier-eslint"
                "richie5um2.vscode-sort-json"
                "bradlc.vscode-tailwindcss"
              ];
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings // {
              # "biome.enabled" = false;
              # "eslint.enable" = false;
              "prettier.enable" = false;
            };
            keybindings = lib.mkIf cfg.declarativeConfig commonKeyBindings;
          };
          Minimal = {
            extensions = [ ];
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
            keybindings = lib.mkIf cfg.declarativeConfig commonKeyBindings;
          };
          Python = {
            extensions =
              commonExtensions
              ++ pkgs.nix4vscode.forVscode [
                "ms-python.python"
                "ms-toolsai.jupyter"
                "njpwerner.autodocstring"
                "charliermarsh.ruff"
              ];
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings;
            keybindings = lib.mkIf cfg.declarativeConfig commonKeyBindings;
          };
          Rust = {
            extensions =
              commonExtensions
              ++ pkgs.nix4vscode.forVscode [
                "rust-lang.rust-analyzer"
              ];
            userSettings = lib.mkIf cfg.declarativeConfig commonSettings // {
              rust-analyzer.check.command = "clippy";
            };
            keybindings = lib.mkIf cfg.declarativeConfig commonKeyBindings;
          };
        };
    };
  };
}
