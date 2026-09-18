{ lib, ... }: {
  flake.modules.nixvim.dev = _: {
    lsp.servers.html.enable = true;

    plugins.conform-nvim.settings.formatters_by_ft.html = [ "prettierd" ];
  };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      programs.opencode = {
        extraPackages = with pkgs; [
          vscode-langservers-extracted
        ];
        settings.lsp.html = {
          command = [
            (lib.getExe' pkgs.vscode-langservers-extracted "vscode-html-language-server")
            "--stdio"
          ];
          extensions = [
            ".html"
          ];
        };
      };
    };
}
