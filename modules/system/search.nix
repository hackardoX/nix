{
  flake.modules.darwin.raycast =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.raycast
      ];
    };
}
