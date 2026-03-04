{
  perSystem.treefmt.programs.nixfmt.enable = true;

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      plugins.conform-nvim.settings = {
        formatters_by_ft.nix = [ "nixfmt" ];
        formatters.nixfmt.command = "${pkgs.nixfmt}/bin/nixfmt";
      };
    };
}
