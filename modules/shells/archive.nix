let
  polyModule =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        zip
        unzip
      ];
    };
in
{
  flake.modules.nixos.base = polyModule;
  flake.modules.darwin.base = polyModule;
}
