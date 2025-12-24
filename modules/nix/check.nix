let
  nixConfig = {
    nix = {
      checkConfig = true;
    };
  };
in
{
  flake.modules.nixos.base = nixConfig;
  flake.modules.darwin.base = nixConfig;
}
