{ lib, config, ... }: {
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      plugins.conform-nvim.luaConfig.post = config.flake.lib.formatRouting.post "web" [
        "css"
        "scss"
        "less"
      ];

      lsp.servers = {
        cssls.enable = true;
        cssls.config.settings = {
          css.lint.unknownAtRules = "ignore";
          scss.lint.unknownAtRules = "ignore";
          less.lint.unknownAtRules = "ignore";
        };
        stylelint_lsp = {
          enable = true;
          config = {
            cmd = [
              (lib.getExe pkgs.stylelint-lsp)
              "--stdio"
            ];
            workspace_required = true;
          };
        };
      };
    };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      programs.opencode = {
        extraPackages = with pkgs; [
          vscode-langservers-extracted
        ];
        settings.lsp.cssls = {
          command = [
            (lib.getExe' pkgs.vscode-langservers-extracted "vscode-css-language-server")
            "--stdio"
          ];
          extensions = [
            ".css"
            ".scss"
            ".less"
          ];
        };
      };
    };
}
