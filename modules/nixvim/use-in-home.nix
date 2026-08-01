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
      system = pkgs.stdenv.hostPlatform.system;
      nixvim = inputs.nixvim.lib.nixvim.modules.buildNixvimWith {
        inherit system;
        modules = [ config.flake.modules.nixvim.dev ];
        extraSpecialArgs.homeConfig = hmArgs.config;
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
