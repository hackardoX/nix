{ lib, ... }:
{
  flake.meta.reverse-proxy = {
    domain = "";
    ports = {
      immich = 9000;
      sure-finance = 19000;
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
      users.users.caddy.extraGroups = [ "acme" ];
      services = {
        geoipupdate = {
          enable = true;
          settings = {
            AccountID = 12345;
            LicenseKeyFile = nixosArgs.config.services.onepassword-secrets.secretPaths.maxmindLicenseKey;
            EditionIDs = [ "GeoLite2-Country" ];
          };
        };

        onepassword-secrets.secrets = {
          maxmindLicenseKey = {
            path = ".secrets/.maxmind_license_key";
            reference = "op://Homelab/MaxMind License Key/credential";
            group = "staff";
          };
        };

        caddy = {
          enable = true;

          package = pkgs.caddy.withPlugins {
            plugins = [
              "github.com/porech/caddy-maxmind-geolocation@v1.0.0"
            ];
            hash = "sha256-your-hash-here";
          };

          extraConfig = ''
            (common_headers) {
              header {
                Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
                X-Content-Type-Options "nosniff"
                X-Frame-Options "SAMEORIGIN"
                X-XSS-Protection "1; mode=block"
                Referrer-Policy "strict-origin-when-cross-origin"
                Permissions-Policy "geolocation=(), microphone=(), camera=()"
                -Server
                -X-Powered-By
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

            (reverse_proxy_common) {
              import common_headers
              import geoblock
              import rate_limit_common
              import tls_hardened

              # Limit request body to 10MB to prevent abuse
              request_body {
                max_size 10MB
              }

              encode zstd gzip

              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }

            # Catch-all: block direct IP access and unknown domains
            :443, :80 {
              abort
            }
          '';
        };
      };
    };
}
