{ lib, ... }: {
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        prettierd
      ];
      plugins = {
        lsp.servers.cssls.enable = true;
        conform-nvim.settings = {
          formatters_by_ft = {
            css = [ "prettierd" ];
            scss = [ "prettierd" ];
            less = [ "prettierd" ];
          };
          formatters = {
            prettierd.command = lib.getExe pkgs.prettierd;
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
