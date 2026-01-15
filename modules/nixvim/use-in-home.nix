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
      # Ideally:
      #nixvim = self.packages.${pkgs.stdenv.hostPlatform.system}.nixvim;
      # but https://github.com/danth/stylix/pull/415#issuecomment-2832398958
      nixvim = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
        inherit pkgs;
        extraSpecialArgs.homeConfig = hmArgs.config;
        module = config.flake.modules.nixvim.dev;
      };
    in
    {
      home = {
        packages = [ nixvim ];
        sessionVariables.EDITOR = lib.getExe nixvim;
      };
    };
}
