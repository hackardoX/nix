{
  flake.modules.homeManager.nix =
    hmArgs@{
      pkgs,
      ...
    }:
    {
      programs.nh = {
        enable = true;
        package = pkgs.nh;
        clean = {
          enable = true;
          extraArgs = "--keep-since 1w --keep 2";
        };
        flake =
          # TODO: make this configurable
          if pkgs.stdenv.hostPlatform.isDarwin then
            "${hmArgs.config.home.homeDirectory}/Github/nix"
          else
            "${hmArgs.config.home.homeDirectory}/nixos-config";
      };
    };
}
