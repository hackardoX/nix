{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        raycast
      ];
    };
}
