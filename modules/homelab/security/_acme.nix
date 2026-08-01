{ config, ... }:
{
  flake.modules.nixos.homelab-security = nixosArgs: {
    security.acme = {
      acceptTerms = true;
      defaults = {
        inherit (config.flake.meta.users.${nixosArgs.config.system.primaryUser}) email;
        dnsProvider = "cloudflare";
        credentialsFile = nixosArgs.config.services.onepassword-secrets.secretPaths.cloudflareApiEnv;
      };
    };

    services.onepassword-secrets.secrets = {
      cloudflareApiEnv = {
        path = "/run/secrets/cloudflare.env";
        reference = "op://Development/CloudFlare DNS API Env - AegisInbox/credential";
        group = "wheel";
      };
    };
  };
}
