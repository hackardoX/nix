_:
let
  # Caddy's combined access log (JSON). Declared in reverse-proxy/default.nix.
  caddyAccessLog = "/var/lib/caddy/access.log";

  # Holds the API key Caddy's bouncer uses. Written by
  # crowdsec-caddy-bouncer-register, read by Caddy (see reverse-proxy).
  caddyBouncerDir = "/var/lib/crowdsec-caddy-bouncer";
  caddyBouncerKey = "${caddyBouncerDir}/api-key";
in
{
  flake.modules.nixos.homelab-security =
    { config, pkgs, ... }:
    let
      cfg = config.services.crowdsec;
    in
    {
      services.crowdsec = {
        enable = true;
        autoUpdateService = true;

        # The unit reads the journal (sshd) and Caddy's access log (group caddy).
        extraGroups = [
          "systemd-journal"
          "caddy"
        ];

        hub.collections = [
          # sshd parsers and scenarios, syslog and geoip enrichment, and the
          # "good actors" allowlists (CDN, search engines, public DNS).
          "crowdsecurity/linux"
          # Caddy log parser and the generic HTTP scenarios (crawling, probing,
          # CVEs, brute force).
          "crowdsecurity/caddy"
        ];

        settings = {
          acquisitions = [
            {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
              labels.type = "syslog";
            }
            {
              # Caddy writes access logs to this file, not to the journal. The
              # parser takes the client from Caddy's client_ip, which honours
              # trusted_proxies (the real visitor behind Cloudflare).
              source = "file";
              filenames = [ caddyAccessLog ];
              labels.type = "caddy";
            }
          ];

          config = {
            # Register with the Central API for the community blocklist. The
            # credentials stay in the (persisted) data directory.
            api.server.online_client.credentials_path = "${cfg.settings.config.config_paths.data_dir}/online_api_credentials.yaml";

            # `cscli metrics` reads this endpoint. Loopback only.
            prometheus = {
              enabled = true;
              level = "full";
              listen_addr = "127.0.0.1";
              listen_port = 6060;
            };
          };

          # Never ban the ways in that are not the public internet: loopback,
          # the LAN and the VPN fallback (Tailscale uses 100.64.0.0/10 and
          # fd7a:115c:a1e0::/48). A forgotten password on the LAN must not lock
          # the owner out of the box.
          parsers.s02Enrich = [
            {
              name = "homelab/whitelist-private-networks";
              description = "Whitelist loopback, LAN and VPN addresses";
              whitelist = {
                reason = "loopback, LAN and VPN";
                cidr = [
                  "127.0.0.0/8"
                  "10.0.0.0/8"
                  "172.16.0.0/12"
                  "192.168.0.0/16"
                  "169.254.0.0/16"
                  "100.64.0.0/10"
                  "::1/128"
                  "fc00::/7"
                  "fe80::/10"
                  "fd7a:115c:a1e0::/48"
                ];
              };
            }
          ];
        };
      };

      # Blocks banned addresses in the kernel (iptables ipset, matching the
      # NixOS firewall) for SSH and any directly exposed port. It registers
      # itself with the local API.
      services.crowdsec-firewall-bouncer.enable = true;

      # Clients that arrive through the Cloudflare tunnel reach Caddy from
      # 127.0.0.1, so the firewall cannot tell them apart. The Caddy bouncer
      # (plugin, see reverse-proxy) checks Caddy's client_ip instead, which
      # works for the tunnel, direct exposure and the VPN alike.
      #
      # The key is created by CrowdSec on every start. Until the first
      # registration Caddy gets a placeholder and simply does not block
      # anything (it fails open); registering reloads Caddy with the real key.
      systemd.tmpfiles.rules = [
        "d ${caddyBouncerDir} 0750 ${cfg.user} caddy -"
        "f ${caddyBouncerKey} 0640 ${cfg.user} caddy - unregistered"
        # Caddy creates its log with mode 0600 unless told otherwise (see
        # reverse-proxy); fix a file that already exists.
        "z ${caddyAccessLog} 0640 caddy caddy -"
      ];

      systemd.services.crowdsec-caddy-bouncer-register = rec {
        description = "Register the Caddy bouncer with the local CrowdSec API";
        wantedBy = [ "multi-user.target" ];
        after = [ "crowdsec.service" ];
        wants = after;
        path = [ cfg.package ];
        script = ''
          set -euo pipefail

          # Replace any previous registration: the key is not kept anywhere
          # but in ${caddyBouncerKey}.
          cscli bouncers delete caddy >/dev/null 2>&1 || true
          key="$(cscli bouncers add caddy --output raw)"
          printf '%s' "$key" > ${caddyBouncerKey}
        '';
        serviceConfig = {
          Type = "oneshot";
          # Caddy only reads its bouncer key when it loads its configuration.
          ExecStartPost = "+${pkgs.systemd}/bin/systemctl try-reload-or-restart caddy.service";

          # cscli reads the local database, so run as the crowdsec user.
          User = cfg.user;
          Group = cfg.group;
          DynamicUser = true;
          ReadWritePaths = [
            "/var/lib/crowdsec"
            caddyBouncerDir
          ];

          LockPersonality = true;
          PrivateDevices = true;
          ProcSubset = "pid";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictAddressFamilies = "none";
          CapabilityBoundingSet = [ "" ];
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
            "~@resources"
          ];
          UMask = "0027";
        };
      };

      # Caddy creates the log file when it starts, and CrowdSec fails to start
      # if the file it is told to read does not exist.
      systemd.services.crowdsec = {
        wants = [ "caddy.service" ];
        after = [ "caddy.service" ];
      };

      # The decision database, hub cache, Central API credentials and the
      # bouncer registration have to survive the root wipe, or every boot would
      # register a new machine.
      boot.initrd.impermanence.persist.directories = [
        {
          directory = "/var/lib/crowdsec";
          inherit (cfg) user;
          inherit (cfg) group;
          mode = "0750";
        }
        {
          directory = "/var/lib/crowdsec-firewall-bouncer-register";
          inherit (cfg) user;
          inherit (cfg) group;
          mode = "0750";
        }
      ];
    };
}
