{
  perSystem.treefmt.programs.yamlfmt.enable = true;

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        prettierd
      ];
      plugins = {
        lsp.servers.yamlls.enable = true;
        conform-nvim.settings = {
          formatters_by_ft = {
            yaml = [ "prettierd" ];
          };
          formatters = {
            prettierd.command = "${pkgs.prettierd}/bin/prettierd";
          };
        };
      };
    };
}
