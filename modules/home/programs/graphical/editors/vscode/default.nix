{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.programs.graphical.editors.vscode;
  aiEnabled = config.${namespace}.suites.development.aiEnable;

  commonExtensions =
    pkgs.nix4vscode.forVscode [
      "1password.op-vscode"
      "adpyke.codesnap"
      "arrterian.nix-env-selector"
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
      "redhat.vscode-yaml"
      "usernamehw.errorlens"
      "yinfei.luahelper"
      "yy0931.gitconfig-lsp"
      "yzhang.markdown-all-in-one"
    ]
    ++ lib.optionals config.${namespace}.suites.development.containerization.enable (
      pkgs.nix4vscode.forVscode [
        "ms-azuretools.vscode-docker"
        "ms-vscode-remote.remote-containers"
      ]
    )
    ++ lib.optionals aiEnabled (
      pkgs.nix4vscode.forVscodePrerelease [
        # "saoudrizwan.claude-dev"
        "continue.continue.1.1.54"
        # "lee2py.aider-composer"
      ]
    );
  commonSettings = {
    # Color theme
    # TODO: Remove once https://github.com/catppuccin/nix/pull/442 is merged
    "window.autoDetectColorScheme" = true;
    "workbench.preferredLightColorTheme" = "Catppuccin Latte";
    "workbench.preferredDarkColorTheme" = "Catppuccin Macchiato";

    # Font family
    "editor.fontFamily" =
      lib.mkForce "MonaspaceArgon, Monaspace Argon, CascadiaCode,Consolas, monospace,Hack Nerd Font";
    # "editor.codeLensFontFamily" =
    #   lib.mkForce "MonaspaceNeon, Monaspace Neon, Liga SFMono Nerd Font, CascadiaCode,Consolas, 'Courier New', monospace,Hack Nerd Font";
    # "editor.inlayHints.fontFamily" = lib.mkForce "MonaspaceKrypton, Monaspace Krypton";
    # "debug.console.fontFamily" = lib.mkForce "MonaspaceKrypton, Monaspace Krypton";
    # "scm.inputFontFamily" = lib.mkForce "MonaspaceRadon, Monaspace Radon";
    # "notebook.output.fontFamily" = lib.mkForce "MonaspaceRadon, Monapsace Radon";
    # "chat.editor.fontFamily" = lib.mkForce "MonaspaceArgon, Monaspace Argon";
    # "markdown.preview.fontFamily" =
    #   lib.mkForce "MonaspaceXenon, Monaspace Xenon; -apple-system, BlinkMacSystemFont, 'Segoe WPC', 'Segoe UI', system-ui, 'Ubuntu', 'Droid Sans', sans-serif";
    # "terminal.integrated.fontFamily" =
    #   lib.mkForce "MonaspaceKrypton, Monaspace Krypton, JetBrainsMono Nerd Font Mono";

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
    # "editor.fontLigatures" =
    #   "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08', 'ss09', 'ss10', 'dlig', 'liga'";
    "editor.fontSize" = lib.mkDefault 12;
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
    "window.menuBarVisibility" = "toggle";
    "window.nativeTabs" = true;
    "window.restoreWindows" = "all";
    "window.titleBarStyle" = "custom";
    "yaml.schemas" = {
      "${config.home.homeDirectory}/.vscode/extensions/continue.continue/config-yaml-schema.json" =
        lib.mkIf aiEnabled
          [
            ".continue/**/*.yaml"
          ];
    };

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
    # "[dockerfile]" = lib.mkIf config.${namespace}.suites.development.containerization.enable {
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
    "continue.telemetryEnabled" = lib.mkIf aiEnabled false;
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
  profiles = {
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
      userSettings = lib.mkIf cfg.declarativeConfig (
        commonSettings
        // {
          "C_Cpp.intelliSenseEngine" = "disabled";
        }
      );
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
          "java.jdt.ls.java.home" = "${pkgs.jdk25}/lib/openjdk";
          "java.configuration.runtimes" = [
            "${pkgs.jdk8}/lib/openjdk"
            "${pkgs.jdk25}/lib/openjdk"
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
          "antfu.iconify"
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
          "tamasfe.even-better-toml"
          "rust-lang.rust-analyzer"
          "vadimcn.vscode-lldb"
        ];
      userSettings = lib.mkIf cfg.declarativeConfig commonSettings // {
        rust-analyzer.check.command = "clippy";
      };
      keybindings = lib.mkIf cfg.declarativeConfig commonKeyBindings;
    };
  };
in
{
  options.${namespace}.programs.graphical.editors.vscode = {
    enable = lib.mkEnableOption "Whether or not to enable vscode";
    declarativeConfig = mkBoolOpt true "Whether or not to enable declarative vscode configuration";
    profiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "The list of vscode profile names";
      readOnly = true;
      default = builtins.attrNames profiles;
    };
  };

  config = lib.mkIf cfg.enable {
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

      inherit profiles;
    };
  };
}
