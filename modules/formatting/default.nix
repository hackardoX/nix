{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        enable = true;
        settings.fail-on-change = false;
        packageOverrides.treefmt = pkgs.treefmt-nix;
      };

      pre-commit.settings.hooks.treefmt.enable = true;
    };
}
