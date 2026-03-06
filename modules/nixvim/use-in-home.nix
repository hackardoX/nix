{
  lib,
  config,
  inputs,
  ...
}:
{
  flake.modules.homeManager.dev =
    hmArgs@{ pkgs, ... }:
    let
      nixvim = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
        inherit pkgs;
        extraSpecialArgs.homeConfig = hmArgs.config;
        module = config.flake.modules.nixvim.dev;
      };
    in
    {
      home = {
        packages = [ nixvim ];
        shellAliases = {
          "v" = lib.getExe nixvim;
        };
        sessionVariables.EDITOR = lib.getExe nixvim;
      };
    };
}
