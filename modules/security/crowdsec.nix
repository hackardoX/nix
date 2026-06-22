{ lib, ... }:
{
  flake.modules.nixos.homelab = nixosArgs: {
    services = {
      crowdsec = {
        enable = true;
        settings.console.tokenFile =
          nixosArgs.config.services.onepassword-secrets.secretPaths.crowdsecConsoleToken;
        localConfig = {
          acquisitions = lib.mkIf nixosArgs.config.services.caddy.enable [
            {
              filenames = [ "/var/log/caddy/access.log" ];
              labels.type = "caddy";
            }
          ];
        };
      };

      onepassword-secrets.secrets = {
        crowdsecConsoleToken = {
          path = "/run/secrets/crowdsec/console_token";
          reference = "op://HomeLab/Crowdsec/console token";
          owner = "crowdsec";
          group = "crowdsec";
          services = [ "crowdsec" ];
        };
      };
    };
  };
}
