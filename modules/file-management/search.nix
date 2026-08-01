{
  flake.modules.homeManager.shell =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.fd
        pkgs.ripgrep
        pkgs.ripgrep-all
      ];
    };
}
