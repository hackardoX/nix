{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        ruff
      ];

      plugins = {
        conform-nvim.settings = {
          formatters_by_ft.python = [ "ruff_format" ];
          formatters.ruff_format.command = "${pkgs.ruff}/bin/ruff";
        };
        dap-python.enable = true;
        lsp.servers.ruff.enable = true;
      };
    };
}
