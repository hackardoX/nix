{ inputs, ... }:
{
  flake.modules.nixos.base = nixosArgs: {
    imports = [ inputs.opnix.nixosModules.default ];
    services.onepassword-secrets = {
      enable = nixosArgs.config.services.onepassword-secrets.secrets != { };
    };
  };

  flake.modules.darwin.base = darwinArgs: {
    imports = [ inputs.opnix.darwinModules.default ];
    services.onepassword-secrets = {
      enable = darwinArgs.config.services.onepassword-secrets.secrets != { };
    };
  };

  flake.modules.homeManager.base = hmArgs: {
    imports = [ inputs.opnix.homeManagerModules.default ];
    programs.onepassword-secrets = {
      enable = hmArgs.config.programs.onepassword-secrets.secrets != { };
    };
  };
}
