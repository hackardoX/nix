{ lib, ... }:
let
  dataDir = "/var/lib/data/crowdsec";
  hubDir = "${dataDir}/hub";
  confDir = "/etc/crowdsec";
in
{
  flake.modules.nixos.homelab =
    { pkgs, ... }:
    let
      # Module bug workaround: the register service uses raw cscli (not the wrapped
      # one that passes -c ${configFile}).  Raw cscli looks for config at the
      # compiled-in default path /etc/crowdsec/config.yaml, which the module never
      # creates.  This file provides the minimal config cscli needs to work.
      crowdsecConfigFile = pkgs.writeText "crowdsec-config.yaml" ''
        config_paths:
          config_dir: ${confDir}
          data_dir: ${dataDir}
          hub_dir: ${hubDir}
          index_path: ${hubDir}/.index.json
        db_config:
          type: sqlite
          db_path: ${dataDir}/crowdsec.db
          use_wal: true
        api:
          server:
            enable: true
            listen_uri: 127.0.0.1:8080
      '';
    in
    {
      # Workaround for register service using raw cscli
      environment.etc."crowdsec/config.yaml".source = crowdsecConfigFile;

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
            # Override paths to use /var/lib/data/crowdsec instead of
            # the module's hardcoded /var/lib/crowdsec.
            # mkForce needed because the module sets these at default priority.
            general.config_paths = {
              data_dir = lib.mkForce dataDir;
              hub_dir = lib.mkForce hubDir;
              index_path = lib.mkForce "${hubDir}/.index.json";
            };
            # db_config uses mkDefault in the module, so plain override works.
            general.db_config.db_path = "${dataDir}/crowdsec.db";
            # Credential files must be set to actual paths (not null) because
            # the module's setup script interpolates them into shell strings.
            lapi.credentialsFile = "${dataDir}/local_api_credentials.yaml";
            capi.credentialsFile = "${dataDir}/online_api_credentials.yaml";
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

      # Fix for DynamicUser + /var/lib/crowdsec permission issue.
      # Also override ReadWritePaths to cover the new data directory.
      systemd.services.crowdsec.serviceConfig = {
        DynamicUser = lib.mkForce false;
        ReadWritePaths = lib.mkForce [
          dataDir
          confDir
        ];
      };

      # Same for the update-hub timer service
      systemd.services.crowdsec-update-hub.serviceConfig = {
        DynamicUser = lib.mkForce false;
        ReadWritePaths = lib.mkForce [
          dataDir
          confDir
        ];
      };

      # Register service: disable DynamicUser so it runs as the static
      # crowdsec user, which owns the new data directory (via tmpfiles below).
      systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
        DynamicUser = lib.mkForce false;
        ReadWritePaths = lib.mkForce [ dataDir ];
      };

      systemd.tmpfiles.settings."10-crowdsec-data" = {
        "${dataDir}".d = {
          user = "crowdsec";
          group = "crowdsec";
          mode = "0750";
        };
        "${hubDir}".d = {
          user = "crowdsec";
          group = "crowdsec";
          mode = "0750";
        };
      };
    };
}
