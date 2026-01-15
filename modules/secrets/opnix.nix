{ inputs, ... }:
{
  flake.modules.nixos.base =
    { config, ... }:
    {
      imports = [ inputs.opnix.nixosModules.default ];
      services.onepassword-secrets = {
        enable = config.services.onepassword-secrets.secrets != { };
      };
    };

  flake.modules.darwin.base =
    { config, ... }:
    {
      imports = [ inputs.opnix.darwinModules.default ];
      services.onepassword-secrets = {
        enable = config.services.onepassword-secrets.secrets != { };
      };
    };

  flake.modules.homeManager.base =
    { config, ... }:
    {
      imports = [ inputs.opnix.homeManagerModules.default ];
      programs.onepassword-secrets = {
        enable = config.programs.onepassword-secrets.secrets != { };
      };
    };
}
