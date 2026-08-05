{ lib, ... }:
{
  flake.lib.types.oidcClient = lib.types.submodule {
    options = {
      clientId = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "OIDC client identifier.";
      };

      clientName = lib.mkOption {
        type = lib.types.str;
        description = "Human-readable OIDC client name.";
      };

      policy = lib.mkOption {
        type = lib.types.str;
        description = "Authelia authorization policy for this client.";
      };

      secretName = lib.mkOption {
        type = lib.types.str;
        description = "1Password secret reference name for the client secret.";
      };

      redirectUris = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Allowed OIDC redirect URIs.";
      };

      extraYamlLines = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra YAML lines merged into the client configuration.";
      };
    };
  };
}
