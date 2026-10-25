{
  flake.modules.homeManager.file-management =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.fd
        pkgs.ripgrep
        pkgs.ripgrep-all
      ];
    };
}
