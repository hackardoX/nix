let
  nixConfig = {
    nix = {
      checkConfig = true;
    };
  };
in
{
  flake.modules.nixos.nix = nixConfig;
  flake.modules.darwin.nix = nixConfig;
}
