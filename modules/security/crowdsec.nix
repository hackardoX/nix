{ ... }:
{
  flake.modules.nixos.homelab = nixosArgs: {
    services = {
      crowdsec = {
        enable = true;
        autoUpdateService = true;
        hub.collections = [
          "crowdsecurity/base-http-scenarios"
          "crowdsecurity/caddy"
          "crowdsecurity/http-cve"
          "crowdsecurity/linux"
          "crowdsecurity/whitelist-good-actors"
        ];
        settings = {
          general.api.server.enable = true;
          general.prometheus.listen_addr = "0.0.0.0";
          lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
          capi.credentialsFile = "/var/lib/crowdsec/state/online_api_credentials.yaml";
        };
        localConfig = {
          acquisitions = [
            {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
              labels.type = "syslog";
            }
            {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=caddy.service" ];
              labels = {
                type = "caddy";
              };
            }
          ];
        };
      };

      crowdsec-firewall-bouncer = {
        enable = true;
        registerBouncer.enable = true;
      };
    };
  };
}
