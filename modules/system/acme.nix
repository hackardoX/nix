{ config, ... }:
{
  flake.modules.nixos.homelab = nixosArgs: {
    security.acme = {
      acceptTerms = true;
      defaults = {
        inherit (config.flake.meta.users.hackardo) email;
        dnsProvider = "cloudflare";
        credentialsFile = nixosArgs.config.services.onepassword-secrets.secretPaths.cloudflareApiEnv;
      };
    };

    services.onepassword-secrets.secrets = {
      cloudflareApiEnv = {
        path = "/etc/.secrets/cloudflare.env";
        reference = "op://Development/CloudFlare DNS API Env - AegisInbox/credential";
        group = "wheel";
      };
    };
  };
}
