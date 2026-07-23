{ config, lib, ... }:
{
  flake.meta.reverse-proxy = {
    domain = "homelab4.fun";
    ports = {
      authelia = 1024;
      homepage = 8000;
      immich = 9000;
      job-ops = 10000;
      reactive-resume = 18000;
      sure-finance = 19000;
      tandoor = 20000;
    };
  };

  flake.modules.nixos.homelab-ingress =
    nixosArgs@{
      pkgs,
      ...
    }:
    let
      domain = config.flake.meta.reverse-proxy.domain;
      geoipDbPath = "/var/lib/GeoIP";
      allowedCountries = [
        "IT"
        "FR"
        "CH"
        "US"
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
            LicenseKey = nixosArgs.config.services.onepassword-secrets.secretPaths.maxmindLicenseKey;
          };
        };

        onepassword-secrets.secrets = {
          maxmindLicenseKey = {
            path = "/run/secrets/.maxmind_license_key";
            reference = "op://Homelab/MaxMind License Key/credential";
            owner = "caddy";
            group = "caddy";
          };
          cloudflareApiToken = {
            path = "/run/secrets/cloudflare_api_token";
            reference = "op://HomeLab/CloudFlare/homelab4.fun/dns api token";
            owner = "caddy";
            group = "caddy";
          };
        };

        caddy = {
          enable = true;

          virtualHosts."*.${domain}" = {
            extraConfig = ''
              abort
            '';
          };

          globalConfig = ''
            acme_dns cloudflare {file./run/secrets/cloudflare_api_token}

            log access-log {
              include http.log.access
              output file /var/lib/caddy/access.log {
                roll_disabled
              }
              format transform "{common_log}"
            }
          '';

          package = pkgs.caddy.withPlugins {
            plugins = [
              "github.com/rfbezerra/caddy-maxmind-geolocation@v0.0.0-20260411180149-e7a64b59e99b"
              "github.com/caddy-dns/cloudflare@v0.2.4"
              "github.com/caddyserver/transform-encoder@v0.0.0-20260423033309-ba4124974830"
              "github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb"
              "github.com/mholt/caddy-ratelimit@v0.1.0"
            ];
            hash = "sha256-U95BTfpifa5TV3vm1Hk5rLKkUYUiAOi0sX/0++lmh2A=";
          };

          extraConfig = ''
            (common_headers) {
              header {
                Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
                X-Content-Type-Options "nosniff"
                X-Frame-Options "SAMEORIGIN"
                Referrer-Policy "strict-origin-when-cross-origin"
                -Server
              }
            }

            (geoblock) {
              @not_allowed {
                not {
                  maxmind_geolocation {
                    db_path "${geoipDbPath}/GeoLite2-Country.mmdb"
                    allow_countries ${lib.concatStringsSep " " allowedCountries}
                    ip_header Cf-Connecting-Ip
                  }
                }
              }
              respond @not_allowed "Forbidden" 403
            }

            (rate_limit_common) {
              rate_limit {
                zone dynamic {
                  key    {http.request.remote.host}
                  events 100
                  window 1m
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
              import common_headers
              import geoblock
              import rate_limit_common
              import tls_hardened

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

      systemd.services.geoipupdate = {
        after = [ "opnix-secrets.service" ];
        wants = [ "opnix-secrets.service" ];
        before = [ "caddy.service" ];
      };

      boot.initrd.impermanence.persist.directories = [
        {
          directory = "/var/lib/caddy";
          user = "caddy";
          group = "caddy";
        }
      ];

      systemd.services.caddy = {
        serviceConfig = {
          Environment = [ "XDG_DATA_HOME=/var/lib" ];
        };
      };
    };
}
