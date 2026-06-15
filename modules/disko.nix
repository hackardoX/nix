{ inputs, ... }: {
  flake.modules.nixos.base = {
    imports = [ inputs.disko.flakeModules.default ];
  };
}
