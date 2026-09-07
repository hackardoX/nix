{ config, ... }:
let
  autheliaService = "authelia-default.service";
  autheliaUser = config.flake.meta.users.authelia.name;
  autheliaGroup = config.flake.meta.users.authelia.primaryGroup;
in
{
  flake.modules.nixos.homelab-security = {
    sops.secrets = {
      "authelia/jwt_secret" = {
        owner = autheliaUser;
        group = autheliaGroup;
        restartUnits = [ autheliaService ];
      };
      "authelia/storage_encryption" = {
        owner = autheliaUser;
        group = autheliaGroup;
        restartUnits = [ autheliaService ];
      };
      "authelia/session_secret" = {
        owner = autheliaUser;
        group = autheliaGroup;
        restartUnits = [ autheliaService ];
      };
      "authelia/oidc_hmac_secret" = {
        owner = autheliaUser;
        group = autheliaGroup;
        restartUnits = [ autheliaService ];
      };
      "authelia/users_file" = {
        sopsFile = ../../../../secrets/homelab/authelia-users.yaml;
        format = "yaml";
        owner = autheliaUser;
        group = autheliaGroup;
        restartUnits = [ autheliaService ];
      };
      "authelia/jwks_key" = {
        owner = autheliaUser;
        group = autheliaGroup;
        restartUnits = [ autheliaService ];
      };
      "authelia/resend_api_key" = {
        owner = autheliaUser;
        group = autheliaGroup;
        restartUnits = [ autheliaService ];
      };
    };
  };
}
