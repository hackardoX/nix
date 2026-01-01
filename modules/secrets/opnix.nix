{ inputs, ... }:
{
  flake.modules.darwin.base = {
    imports = [ inputs.opnix.darwinModules.default ];
  };

  flake.modules.homeManager.base = {
    imports = [ inputs.opnix.homeManagerModules.default ];
    programs = {
      onepassword-secrets = {
        enable = true;
      };
    };
  };
}
