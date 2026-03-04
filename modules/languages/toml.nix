{
  perSystem.treefmt.programs.taplo = {
    enable = true;
    settings.formatting = {
      reorder_keys = true;
      reorder_arrays = true;
      reorder_inline_tables = true;
      allowed_blank_lines = 1;
    };
  };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        taplo
      ];

      plugins.conform-nvim.settings = {
        formatters_by_ft = {
          toml = [ "taplo" ];
        };
        formatters = {
          taplo.command = "${pkgs.taplo}/bin/taplo";
        };
      };
    };
}
