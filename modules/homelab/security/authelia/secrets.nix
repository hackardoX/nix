{ config, ... }:
let
  autheliaService = "authelia-default.service";
in
{
  flake.modules.nixos.homelab-security = {
    services.onepassword-secrets.secrets = {
      autheliaJwtSecret = {
        path = "/run/secrets/authelia/jwt_secret";
        reference = "op://HomeLab/Authelia/JWT Secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaStorageEncryption = {
        path = "/run/secrets/authelia/storage_encryption";
        reference = "op://HomeLab/Authelia/Storage Encryption Key";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaSessionSecret = {
        path = "/run/secrets/authelia/session_secret";
        reference = "op://HomeLab/Authelia/Session Secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaOidcHmacSecret = {
        path = "/run/secrets/authelia/oidc_hmac_secret";
        reference = "op://HomeLab/Authelia/OIDC HMAC Secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaUsersFile = {
        path = "/run/secrets/authelia/users.yml";
        reference = "op://HomeLab/Authelia Users/notesPlain";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaJwksKey = {
        path = "/run/secrets/authelia/jwks_key";
        reference = "op://HomeLab/Authelia JWKS Key/private key";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaResendApiKey = {
        path = "/run/secrets/authelia/resend_api_key";
        reference = "op://HomeLab/Authelia/Resend/api key";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
    };
  };
}
