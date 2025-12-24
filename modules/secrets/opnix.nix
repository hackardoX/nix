{ inputs, ... }:
{
  flake.modules.darwin.base = {
    imports = [ inputs.opnix.darwinModules.default ];
  };
}
