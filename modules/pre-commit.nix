{
  perSystem =
    { pkgs, ... }:
    {
      pre-commit.settings.package = pkgs.prek;
    };
}
