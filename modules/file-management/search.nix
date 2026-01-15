{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.fd
        pkgs.ripgrep
        pkgs.ripgrep-all
      ];
    };
}
