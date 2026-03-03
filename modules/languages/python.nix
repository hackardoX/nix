{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        ruff
      ];

      plugins = {
        lsp.servers.ruff.enable = true;

        conform-nvim.settings = {
          formatters_by_ft.python = [ "ruff_format" ];
          formatters.ruff_format.command = "${pkgs.ruff}/bin/ruff";
        };
      };
    };
}
