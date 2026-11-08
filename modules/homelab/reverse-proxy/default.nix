{ config, lib, ... }:
let
  domain = "homelab4.fun";
in
{
  flake.meta.reverse-proxy = {
    inherit domain;
    hosts = {
      auth = "auth.${domain}";
      homepage = "homepage.${domain}";
      immich = "photos.${domain}";
      jobs = "jobs.${domain}";
      monitoring = "monitoring.${domain}";
      rxresume = "rxresume.${domain}";
      recipes = "recipes.${domain}";
      timeline = "timeline.${domain}";
      finance = "finance.${domain}";
      grafana = "grafana.${domain}";
      logs = "logs.${domain}";
      ssh = "ssh.${domain}";
      backup = "backup.${domain}";
    };
    ports = {
      authelia = 1024;
      beszel = 2000;
      beszel-agent-alerting = 2001;
      beszel-agent-homepage = 2002;
      beszel-agent-job-ops = 2003;
      beszel-agent-reactive-resume = 2004;
      beszel-agent-sure-finance = 2005;
      beszel-agent-tandoor = 2006;
      beszel-agent-immich = 2007;
      beszel-agent-homelab = 2008;
      beszel-agent-monitoring = 2009;
      beszel-agent-dawarich = 2010;
      homepage = 8000;
      homepage-docker-socket-proxy = 8001;
      immich = 9000;
      immich-docker-socket-proxy = 9001;
      job-ops = 10000;
      job-ops-docker-socket-proxy = 10001;
      dawarich = 11000;
      dawarich-docker-socket-proxy = 11001;
      grafito = 7000;
      reactive-resume = 18000;
      reactive-resume-docker-socket-proxy = 18001;
      sure-finance = 19000;
      sure-finance-docker-socket-proxy = 19001;
      tandoor = 20000;
      tandoor-docker-socket-proxy = 20001;
      backup = 2100;
      # Read-only view of Caddy's admin API for the Homepage widget.
      caddy-upstreams = 2020;
    };
  };

  flake.meta.homepage.services.caddy = {
    category = "Monitoring";
    name = "Caddy";
    description = "Reverse Proxy";
    icon = "sh-caddy.webp";
    widget = {
      type = "caddy";
      url = "http://localhost:${toString config.flake.meta.reverse-proxy.ports.caddy-upstreams}";
    };
    pingPort = config.flake.meta.reverse-proxy.ports.caddy-upstreams;
  };

  flake.modules.nixos.homelab-ingress =
    nixosArgs@{
      pkgs,
      ...
    }:
    let
      domain = config.flake.meta.reverse-proxy.domain;
      geoipDbPath = "/var/lib/caddy/GeoIP";
      allowedCountries = [
        "IT"
        "FR"
        "CH"
        "US"
        "BE"
      ];
    in
    {
      services = {
        geoipupdate = {
          enable = true;
          settings = {
            AccountID = 1353550;
            DatabaseDirectory = geoipDbPath;
            EditionIDs = [ "GeoLite2-Country" ];
            LicenseKey = nixosArgs.config.sops.secrets."ingress/maxmind_license_key".path;
          };
        };

        caddy = {
          enable = true;

          virtualHosts."*.${domain}" = {
            extraConfig = ''
              abort
            '';
          };

          # The Homepage widget needs /reverse_proxy/upstreams from the admin
          # API. The admin API itself can rewrite the whole config, so the
          # Homepage container only gets this loopback listener, which
          # forwards that one GET and nothing else.
          virtualHosts."http://127.0.0.1:${toString config.flake.meta.reverse-proxy.ports.caddy-upstreams}" = {
            extraConfig = ''
              bind 127.0.0.1
              @upstreams {
                method GET
                path /reverse_proxy/upstreams
              }
              handle @upstreams {
                reverse_proxy 127.0.0.1:2019 {
                  header_up Host 127.0.0.1:2019
                }
              }
              handle {
                respond 404
              }
            '';
          };

          globalConfig = ''
            acme_dns cloudflare {file.${nixosArgs.config.sops.secrets."ingress/cloudflare_api_token".path}}

            # Blocks clients CrowdSec has banned. It checks Caddy's client_ip, so
            # it also works for visitors arriving through the Cloudflare tunnel.
            # The key file is written by crowdsec-caddy-bouncer-register
            # (homelab-security). Without a valid key, or if CrowdSec is down,
            # nothing is blocked and Caddy keeps serving.
            order crowdsec first
            crowdsec {
              api_url http://127.0.0.1:8080
              api_key {file./var/lib/crowdsec-caddy-bouncer/api-key}
              ticker_interval 15s
            }

            # Read by CrowdSec (acquisition in security/crowdsec.nix).
            log access-log {
              include http.log.access
              output file /var/lib/caddy/access.log {
                mode 0640
                roll_size 100MiB
                roll_keep 10
                roll_keep_for 720h
              }
            }
          '';

          # doInstallCheck is off because nixpkgs looks the plugin up in the
          # binary's build info by the path given here, and the crowdsec
          # bouncer is a package inside a module (.../http in
          # github.com/hslatman/caddy-crowdsec-bouncer). validate-caddy proves
          # the plugin is compiled in.
          package = (pkgs.caddy.withPlugins {
            plugins = [
              "github.com/rfbezerra/caddy-maxmind-geolocation@v0.0.0-20260411180149-e7a64b59e99b"
              "github.com/caddy-dns/cloudflare@v0.2.4"
              "github.com/caddyserver/transform-encoder@v0.0.0-20260423033309-ba4124974830"
              "github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb"
              "github.com/mholt/caddy-ratelimit@v0.1.0"
              "github.com/fvbommel/caddy-combine-ip-ranges@v0.0.2-0.20240127132546-5624d08f5f9e"
              "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.15.0"
            ];
            hash = "sha256-MvYIQlS3PzufPSPSKqbXiARpau5Pq59I6WVDvYx2Ldo=";
          }).overrideAttrs
            { doInstallCheck = false; };

          extraConfig = ''
            (common_headers) {
              header {
                Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
                X-Content-Type-Options "nosniff"
                X-Frame-Options "SAMEORIGIN"
                Referrer-Policy "strict-origin-when-cross-origin"
                # Only the framing/base/plugin directives, which apps rarely
                # need. The "?" prefix keeps an app's own, stricter CSP (e.g.
                # Authelia's) instead of overwriting it.
                ?Content-Security-Policy "frame-ancestors 'self'; base-uri 'self'; object-src 'none'"
                -Server
              }
            }

            # No ip_header here: the matcher then uses Caddy's client_ip, which
            # honours trusted_proxies. X-Forwarded-For is client-controlled and
            # the plugin reads its first value, so it would bypass the filter.
            (geoblock) {
              @not_allowed {
                not {
                  maxmind_geolocation {
                    db_path "${geoipDbPath}/GeoLite2-Country.mmdb"
                    allow_countries ${lib.concatStringsSep " " allowedCountries}
                  }
                }
              }
              respond @not_allowed "Forbidden: Access from your country is not allowed" 403
            }

            (rate_limit_common) {
              rate_limit {
                zone dynamic {
                  match {
                    path /api/* /auth/* /login /graphql
                  }
                  key    {http.request.client_ip}
                  events 300
                  window 1m
                  ipv6_prefix 64
                  log_key
                }
              }
            }

            (tls_hardened) {
              tls {
                protocols tls1.2 tls1.3
                ciphers TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256 TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
              }
            }

            (reverse_proxy_common) {
              crowdsec
              import common_headers
              import geoblock
              import tls_hardened
              import rate_limit_common

              request_body {
                max_size 10MB
              }

              encode zstd gzip
            }

            # Catch-all: block direct IP access and unknown domains
            :443, :80 {
              abort
            }
          '';
        };
      };

      sops.secrets = {
        "ingress/maxmind_license_key" = {
          owner = "caddy";
          group = "caddy";
        };
        "ingress/cloudflare_api_token" = {
          owner = "caddy";
          group = "caddy";
        };
      };

      users.users.caddy.extraGroups = [ "homelab-users" ];

      systemd.services.caddy = {
        serviceConfig = {
          Environment = [ "XDG_DATA_HOME=/var/lib" ];
          Restart = "on-failure";
          RestartSec = "5s";
        };
        wants = [
          "geoipupdate.service"
        ];
        after = [
          "geoipupdate.service"
        ];
      };

      boot.initrd.impermanence.persist.directories = [
        {
          directory = "/var/lib/caddy";
          user = "caddy";
          group = "caddy";
          mode = "0750";
        }
      ];
    };
}
