{
  perSystem.treefmt.programs = {
    nixf-diagnose.enable = true;
    statix = {
      enable = true;
    };
  };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        nixfmt
      ];

      plugins.conform-nvim.settings = {
        formatters_by_ft.nix = [ "nixfmt" ];
        formatters.nixfmt.command = "${pkgs.nixfmt}/bin/nixfmt";
      };

      plugins.lsp.servers = {
        nixd.enable = true;
        statix.enable = true;
      };
    };
}
