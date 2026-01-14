{
  configurations.nixos.Hetzner-HomeLab.module =
    { config, ... }:
    {
      home-manager.users.${config.system.primaryUser}.programs.onepassword-secrets.secrets = {
        hetznerUserPassword = {
          path = ".secrets/.password";
          reference = "op://Development/Hetzner HomeLab/user password";
          group = "staff";
        };
      };
    };
}
