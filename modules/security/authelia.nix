{ config, lib, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  authDomain = "auth.${domain}";
  autheliaPort = config.flake.meta.reverse-proxy.ports.authelia;
in
{
  flake.meta.oidc-clients = {
    immich = {
      clientId = "immich";
      clientName = "Immich";
    };
    tandoor = {
      clientId = "tandoor";
      clientName = "Tandoor Recipes";
    };
  };

  flake.modules.nixos.homelab =
    nixosArgs:
    let
      autheliaUsers = {
        hal = {
          displayname = config.flake.meta.users.hal.description;
          email = config.flake.meta.users.hal.email;
          passwordHashFile =
            nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaHalPasswordHash;
        };
      };
    in
    {
      services = {
        authelia = {
          instances.default = {
            enable = true;
            settings = {
              theme = "dark";
              default_redirection_url = "https://${domain}";
              log.level = "info";
              server = {
                host = "127.0.0.1";
                port = autheliaPort;
              };
              totp = {
                issuer = domain;
                period = 30;
                skew = 1;
              };
              webauthn = {
                enable_passkey_login = true;
              };
              authentication_backend = {
                file.path = "/var/lib/authelia/users.yml";
                password_reset.disable = false;
              };
              access_control = {
                default_policy = "deny";
                rules = [
                  {
                    domain = authDomain;
                    policy = "bypass";
                  }
                  {
                    domain = domain;
                    policy = "one_factor";
                  }
                  {
                    domain = "*.${domain}";
                    policy = "one_factor";
                  }
                ];
              };
              session = {
                name = "authelia_session";
                cookies = [
                  {
                    domain = domain;
                    authelia_url = "https://${authDomain}";
                    inactivity = "1h";
                    expiration = "1d";
                    remember_me = "1M";
                  }
                ];
              };
              regulation = {
                max_retries = 3;
                find_time = "1h";
                ban_time = "1w";
              };
              storage = {
                local.path = "/var/lib/authelia/db.sqlite3";
              };
              notifier.smtp = {
                address = "smtp://smtp.resend.com:587";
                username = "resend";
                sender = "authelia@${domain}";
              };
              identity_providers.oidc = {
                cors = {
                  endpoints = [ "token" ];
                  allowed_origins = [ "https://immich.${domain}" ];
                };
              };
            };
            secrets = {
              jwtSecretFile = nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaJwtSecret;
              storageEncryptionKeyFile =
                nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaStorageEncryption;
              sessionSecretFile = nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaSessionSecret;
              oidcHmacSecretFile =
                nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaOidcHmacSecret;
              oidcIssuerPrivateKeyFile =
                nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaJwksKey;
            };
            environmentVariables = {
              AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE =
                nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaSmtpPassword;
            };
            settingsFiles = [
              (builtins.toFile "oidc_clients.yaml" ''
                identity_providers:
                  oidc:
                    clients:
                      - client_id: "${config.flake.meta.oidc-clients.immich.clientId}"
                        client_name: "${config.flake.meta.oidc-clients.immich.clientName}"
                        public: false
                        authorization_policy: "one_factor"
                        client_secret: {{ secret "${nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaImmichOidcSecret}" | msquote }}
                        redirect_uris:
                          - "https://immich.${domain}/auth/login-callback"
                          - "https://immich.${domain}/api/oauth/mobile"
                        scopes:
                          - "openid"
                          - "profile"
                          - "email"
                      - client_id: "${config.flake.meta.oidc-clients.tandoor.clientId}"
                        client_name: "${config.flake.meta.oidc-clients.tandoor.clientName}"
                        public: false
                        authorization_policy: "one_factor"
                        client_secret: {{ secret "${nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaTandoorOidcSecret}" | msquote }}
                        redirect_uris:
                          - "https://recipes.${domain}/accounts/oidc/authelia/login/callback/"
                        scopes:
                          - "openid"
                          - "profile"
                          - "email"
              '')
            ];
          };
        };

        caddy = {
          virtualHosts."${authDomain}" = {
            useACMEHost = domain;
            extraConfig = ''
              import reverse_proxy_internal
              reverse_proxy localhost:${toString autheliaPort}
            '';
          };

          extraConfig = lib.mkAfter ''
            (auth_protected) {
              forward_auth localhost:${toString autheliaPort} {
                uri /api/authz/forward-auth
                request_header X-Forwarded-Method             {method}
                request_header X-Forwarded-URI                {uri}
                request_header X-Forwarded-Host               {host}
                request_header X-Forwarded-Proto              {scheme}
                request_header X-Forwarded-Remote-User        {http.auth.header.remote_user}
                request_header X-Forwarded-Remote-Groups      {http.auth.header.remote_groups}
                request_header X-Forwarded-Remote-Name        {http.auth.header.remote_name}
                request_header X-Forwarded-Remote-Email       {http.auth.header.remote_email}
              }
            }

            (reverse_proxy_internal) {
              import common_headers
              import tls_hardened

              encode zstd gzip

              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
          '';
        };

        onepassword-secrets.secrets = {
          autheliaJwtSecret = {
            path = "/run/secrets/authelia/jwt_secret";
            reference = "op://Homelab/Authelia/JWT Secret/credential";
            owner = "authelia";
            group = "authelia";
          };
          autheliaStorageEncryption = {
            path = "/run/secrets/authelia/storage_encryption";
            reference = "op://Homelab/Authelia/Storage Encryption Key/credential";
            owner = "authelia";
            group = "authelia";
          };
          autheliaSessionSecret = {
            path = "/run/secrets/authelia/session_secret";
            reference = "op://Homelab/Authelia/Session Secret/credential";
            owner = "authelia";
            group = "authelia";
          };
          autheliaOidcHmacSecret = {
            path = "/run/secrets/authelia/oidc_hmac_secret";
            reference = "op://Homelab/Authelia/OIDC HMAC Secret/credential";
            owner = "authelia";
            group = "authelia";
          };
          autheliaHalPasswordHash = {
            path = "/run/secrets/authelia/hal_password_hash";
            reference = "op://Homelab/Authelia/HAL Password Hash/credential";
            owner = "authelia";
            group = "authelia";
          };
          autheliaJwksKey = {
            path = "/run/secrets/authelia/jwks_key";
            reference = "op://Homelab/Authelia/JWKS Key/credential";
            owner = "authelia";
            group = "authelia";
          };
          autheliaSmtpPassword = {
            path = "/run/secrets/authelia/smtp_password";
            reference = "op://Homelab/Authelia/SMTP Password/credential";
            owner = "authelia";
            group = "authelia";
          };
          autheliaImmichOidcSecret = {
            path = "/run/secrets/authelia/immich_oidc_secret";
            reference = "op://Homelab/Authelia/Immich OIDC Client Secret/credential";
            owner = "authelia";
            group = "authelia";
          };
          autheliaTandoorOidcSecret = {
            path = "/run/secrets/authelia/tandoor_oidc_secret";
            reference = "op://Homelab/Authelia/Tandoor OIDC Client Secret/credential";
            owner = "authelia";
            group = "authelia";
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/authelia 0750 authelia authelia -"
      ];

      systemd.services.authelia-instance-default = {
        serviceConfig.Environment = "X_AUTHELIA_CONFIG_FILTERS=template";
      };

      systemd.services.authelia-init = {
        description = "Initialize Authelia user database";
        before = [ "authelia-instance-default.service" ];
        requiredBy = [ "authelia-instance-default.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "authelia";
          Group = "authelia";
        };
        script =
          "cat > /var/lib/authelia/users.yml << EOF\n"
          + "users:\n"
          + lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              name: user:
              "  ${name}:\n"
              + "    disabled: false\n"
              + "    displayname: \"${user.displayname}\"\n"
              + "    password: $(cat \"${user.passwordHashFile}\")\n"
              + "    email: \"${user.email}\"\n"
              + "    groups: []"
            ) autheliaUsers
          )
          + "\nEOF";
      };
    };
}
