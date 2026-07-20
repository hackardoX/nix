{ lib, ... }:
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

  flake.modules.nixos.homelab =
    nixosArgs@{
      pkgs,
      ...
    }:
    let
      geoipDbPath = "/var/lib/GeoIP/GeoLite2-Country.mmdb";
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
            LicenseKey = nixosArgs.config.services.onepassword-secrets.secretPaths.maxmindLicenseKey;
            EditionIDs = [ "GeoLite2-Country" ];
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

          globalConfig = ''
            acme_dns cloudflare {file./run/secrets/cloudflare_api_token}

            log {
              output file /var/log/caddy/access.log {
                roll_disabled
              }
              format transform "{common_log}"
            }
          '';

          package = pkgs.caddy.withPlugins {
            plugins = [
              "github.com/porech/caddy-maxmind-geolocation@v1.0.3"
              "github.com/caddy-dns/cloudflare@v0.2.4"
              "github.com/caddyserver/transform-encoder"
            ];
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
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
              maxmind_geolocation {
                db_path "${geoipDbPath}"
                allow_countries ${lib.concatStringsSep " " allowedCountries}
              }
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

            # (reverse_proxy_common) {
            #   import common_headers
            #   import geoblock
            #   import rate_limit_common
            #   import tls_hardened
            #   import auth_protected
            #
            #   request_body {
            #     max_size 10MB
            #   }
            #
            #   encode
            #
            #   header_up X-Real-IP {remote_host}
            # }

            # Catch-all: block direct IP access and unknown domains
            :443, :80 {
              abort
            }
          '';
        };
      };

      systemd.services.caddy = {
        after = [ "opnix-secrets.service" ];
        wants = [ "opnix-secrets.service" ];
        serviceConfig.ReadWritePaths = [ "/var/log/caddy" ];
      };

      systemd.tmpfiles.rules = [ "d /var/log/caddy 0755 caddy caddy -" ];
    };
}
