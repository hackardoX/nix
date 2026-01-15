{ lib, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      plugins.grug-far = {
        enable = true;
        settings = {
          engine = "ripgrep";
          engines.ripgrep.path = lib.getExe pkgs.ripgrep-all;
        };
      };
    };
}
