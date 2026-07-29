{ inputs, ... }: {
  flake.modules.nixvim.dev = {
    nixpkgs.source = inputs.nixpkgs;
  };
}
