{ inputs, ... }:
let
  dataDir = "/var/lib/data/crowdsec";
in
{
  flake.modules.nixos.security =
    { pkgs, ... }:
    {
      disabledModules = [ "services/security/crowdsec.nix" ];
      imports = [
        "${inputs.nixpkgs-crowdsec}/nixos/modules/services/security/crowdsec.nix"
      ];

      users.users.crowdsec.extraGroups = [ "caddy" ];

      services = {
        crowdsec = {
          enable = true;
          autoUpdateService = true;
          package = pkgs.callPackage "${inputs.nixpkgs-crowdsec}/pkgs/by-name/cr/crowdsec/package.nix" { };
          hub.collections = [
            "crowdsecurity/linux"
            "crowdsecurity/sshd"
            "crowdsecurity/caddy"
            "crowdsecurity/base-http-scenarios"
            "crowdsecurity/http-cve"
            "crowdsecurity/whitelist-good-actors"
          ];
          settings = {
            acquisitions = [
              {
                source = "journalctl";
                journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
                labels.type = "syslog";
              }
              {
                source = "journalctl";
                journalctl_filter = [ "_SYSTEMD_UNIT=caddy.service" ];
                labels.type = "caddy";
              }
            ];
            config.api.server.online_client.credentials_path = "${dataDir}/online_api_credentials.yaml";
            config.api.server.listen_uri = "127.0.0.1:8080";
            config.prometheus = {
              enabled = true;
              listen_addr = "0.0.0.0";
            };
            config_paths.data_dir = dataDir;
            config_paths.hub_dir = "${dataDir}/hub";
            config_paths.index_path = "${dataDir}/hub/.index.json";
            db_config.db_path = "${dataDir}/crowdsec.db";
            db_config.type = "sqlite";
            db_config.use_wal = true;
          };
        };

        crowdsec-firewall-bouncer = {
          enable = true;
          settings = {
            mode = "iptables";
            api_url = "http://127.0.0.1:8080";
          };
          registerBouncer.enable = false;
          secrets.apiKeyPath = "${dataDir}/bouncer-key";
        };
      };
    };
}
