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
        reference = "op://HomeLab/Resend/Authelia/api key";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaBeszelOidcSecret = {
        path = "/run/secrets/authelia/beszel_oidc_secret";
        reference = "op://HomeLab/Beszel/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaImmichOidcSecret = {
        path = "/run/secrets/authelia/immich_oidc_secret";
        reference = "op://HomeLab/Immich/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaTandoorOidcSecret = {
        path = "/run/secrets/authelia/tandoor_oidc_secret";
        reference = "op://HomeLab/Tandoor/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaGrafanaOidcSecret = {
        path = "/run/secrets/authelia/grafana_oidc_secret";
        reference = "op://HomeLab/Grafana/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaReactiveResumeOidcSecret = {
        path = "/run/secrets/authelia/reactive-resume_oidc_secret";
        reference = "op://HomeLab/Reactive Resume/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaSureFinanceOidcSecret = {
        path = "/run/secrets/authelia/sure-finance_oidc_secret";
        reference = "op://HomeLab/Sure Finance/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
      autheliaDawarichOidcSecret = {
        path = "/run/secrets/authelia/dawarich_oidc_secret";
        reference = "op://HomeLab/Dawarich/Authentication/OIDC client secret";
        owner = config.flake.meta.users.authelia.name;
        group = config.flake.meta.users.authelia.primaryGroup;
        services = [ autheliaService ];
      };
    };
  };
}
