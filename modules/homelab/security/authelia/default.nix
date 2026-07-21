{ config, lib, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  authDomain = "auth.${domain}";
  autheliaPort = config.flake.meta.reverse-proxy.ports.authelia;
in
{
  flake.meta = {
    authelia = {
      user = "authelia-default";
      group = "authelia-default";
    };

    oidc-clients = {
      immich = {
        clientId = "immich";
        clientName = "Immich";
      };
      tandoor = {
        clientId = "tandoor";
        clientName = "Tandoor Recipes";
      };
      grafana = {
        clientId = "grafana";
        clientName = "Grafana";
      };
      reactive-resume = {
        clientId = "reactive-resume";
        clientName = "Reactive Resume";
      };
    };
  };

  flake.modules.nixos.security =
    nixosArgs@{ pkgs, ... }:
    let
      autheliaService = "authelia-default.service";
      autheliaUsers = {
        hal = {
          displayname = config.flake.meta.users.hal.description;
          email = config.flake.meta.users.hal.email;
          passwordHashFile =
            nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaHalPasswordHash;
        };
      };

      autheliaDataDir = "/var/lib/data/authelia";
      hashedSecretsDir = "${autheliaDataDir}/hashed-oidc-secrets";

      oidcClients = [
        {
          name = "immich";
          secretPath = nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaImmichOidcSecret;
        }
        {
          name = "tandoor";
          secretPath = nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaTandoorOidcSecret;
        }
        {
          name = "grafana";
          secretPath = nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaGrafanaOidcSecret;
        }
        {
          name = "reactive-resume";
          secretPath =
            nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaReactiveResumeOidcSecret;
        }
      ];
    in
    {
      services = {
        authelia = {
          instances.default = {
            enable = true;
            settings = {
              theme = "dark";
              log.level = "info";
              server = {
                address = "tcp://127.0.0.1:${toString autheliaPort}";
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
                file.path = "${autheliaDataDir}/users.yml";
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
                    default_redirection_url = "https://${domain}";
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
                local.path = "${autheliaDataDir}/db.sqlite3";
              };
              notifier.smtp = {
                address = "smtp://smtp.resend.com:587";
                username = "resend";
                sender = "authelia@${domain}";
              };
              identity_providers.oidc = {
                cors = {
                  endpoints = [ "token" ];
                  allowed_origins = [
                    "https://immich.${domain}"
                    "https://grafana.${domain}"
                    "https://rxresume.${domain}"
                  ];
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
                nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaResendApiKey;
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
                        token_endpoint_auth_method: "client_secret_post"
                        client_secret: {{ secret "${hashedSecretsDir}/immich_oidc_secret" | msquote }}
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
                        token_endpoint_auth_method: "client_secret_post"
                        client_secret: {{ secret "${hashedSecretsDir}/tandoor_oidc_secret" | msquote }}
                        redirect_uris:
                          - "https://recipes.${domain}/accounts/oidc/authelia/login/callback/"
                        scopes:
                          - "openid"
                          - "profile"
                          - "email"
                      - client_id: "${config.flake.meta.oidc-clients.grafana.clientId}"
                        client_name: "${config.flake.meta.oidc-clients.grafana.clientName}"
                        public: false
                        authorization_policy: "one_factor"
                        token_endpoint_auth_method: "client_secret_post"
                        client_secret: {{ secret "${hashedSecretsDir}/grafana_oidc_secret" | msquote }}
                        redirect_uris:
                          - "https://grafana.${domain}/login/generic_oauth"
                        scopes:
                          - "openid"
                          - "profile"
                          - "email"
                      - client_id: "${config.flake.meta.oidc-clients.reactive-resume.clientId}"
                        client_name: "${config.flake.meta.oidc-clients.reactive-resume.clientName}"
                        public: false
                        authorization_policy: "one_factor"
                        token_endpoint_auth_method: "client_secret_post"
                        client_secret: {{ secret "${hashedSecretsDir}/reactive-resume_oidc_secret" | msquote }}
                        redirect_uris:
                          - "https://rxresume.${domain}/api/auth/callback"
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
            extraConfig = ''
              import reverse_proxy_internal
              reverse_proxy localhost:${toString autheliaPort}
            '';
          };

          extraConfig = lib.mkAfter ''
            (auth_protected) {
              forward_auth localhost:${toString autheliaPort} {
                uri /api/authz/forward-auth
                header_up X-Forwarded-Method             {method}
                header_up X-Forwarded-URI                {uri}
                header_up X-Forwarded-Host               {host}
                header_up X-Forwarded-Proto              {scheme}
                header_up X-Forwarded-Remote-User        {http.auth.header.remote_user}
                header_up X-Forwarded-Remote-Groups      {http.auth.header.remote_groups}
                header_up X-Forwarded-Remote-Name        {http.auth.header.remote_name}
                header_up X-Forwarded-Remote-Email       {http.auth.header.remote_email}
              }
            }

            (reverse_proxy_internal) {
              import common_headers
              import tls_hardened

              encode zstd gzip
            }
          '';
        };

        onepassword-secrets.secrets = {
          autheliaJwtSecret = {
            path = "/run/secrets/authelia/jwt_secret";
            reference = "op://HomeLab/Authelia/JWT Secret";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaStorageEncryption = {
            path = "/run/secrets/authelia/storage_encryption";
            reference = "op://HomeLab/Authelia/Storage Encryption Key";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaSessionSecret = {
            path = "/run/secrets/authelia/session_secret";
            reference = "op://HomeLab/Authelia/Session Secret";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaOidcHmacSecret = {
            path = "/run/secrets/authelia/oidc_hmac_secret";
            reference = "op://HomeLab/Authelia/OIDC HMAC Secret";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaHalPasswordHash = {
            path = "/run/secrets/authelia/hal_password_hash";
            reference = "op://HomeLab/Authelia/HAL Password Hash";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaJwksKey = {
            path = "/run/secrets/authelia/jwks_key";
            reference = "op://HomeLab/Authelia JWKS Key/private key";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaResendApiKey = {
            path = "/run/secrets/authelia/resend_api_key";
            reference = "op://HomeLab/Resend/Authelia/api key";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaImmichOidcSecret = {
            path = "/run/secrets/authelia/immich_oidc_secret";
            reference = "op://HomeLab/Immich/Authentication/OIDC client secret";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaTandoorOidcSecret = {
            path = "/run/secrets/authelia/tandoor_oidc_secret";
            reference = "op://HomeLab/Tandoor/Authentication/OIDC client secret";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaGrafanaOidcSecret = {
            path = "/run/secrets/authelia/grafana_oidc_secret";
            reference = "op://HomeLab/Grafana/Authentication/OIDC client secret";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
          autheliaReactiveResumeOidcSecret = {
            path = "/run/secrets/authelia/reactive-resume_oidc_secret";
            reference = "op://HomeLab/Reactive Resume/Authentication/OIDC client secret";
            owner = config.flake.meta.authelia.user;
            group = config.flake.meta.authelia.group;
            services = [ autheliaService ];
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${hashedSecretsDir} 0750 ${config.flake.meta.authelia.user} ${config.flake.meta.authelia.group} -"
      ];

      systemd.services.authelia-init = {
        description = "Initialize Authelia user database";
        before = [ "authelia-default.service" ];
        requiredBy = [ "authelia-default.service" ];
        after = [ "opnix-secrets.service" ];
        wants = [ "opnix-secrets.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = config.flake.meta.authelia.user;
          Group = config.flake.meta.authelia.group;
        };
        script = lib.concatStringsSep "\n" (
          [
            ''
              hash_secret() {
                local src="$1" dst="$2"
                local secret
                secret=$(<"$src")
                "${lib.getExe pkgs.authelia}" crypto hash generate pbkdf2 \
                  --variant sha512 --no-confirm --password "$secret" \
                  | sed -n 's/^Digest: //p' > "$dst"
              }
            ''
          ]
          ++ lib.forEach oidcClients (
            c: ''hash_secret "${c.secretPath}" "${hashedSecretsDir}/${c.name}_oidc_secret"''
          )
          ++ [
            "cat > \"${autheliaDataDir}/users.yml\" << EOF"
            "users:"
          ]
          ++ lib.mapAttrsToList (
            name: user:
            "  ${name}:\n"
            + "    disabled: false\n"
            + "    displayname: \"${user.displayname}\"\n"
            + "    password: $(cat \"${user.passwordHashFile}\")\n"
            + "    email: \"${user.email}\"\n"
            + "    groups: []"
          ) autheliaUsers
          ++ [ "EOF" ]
        );
      };

      systemd.services.authelia-default.serviceConfig.StateDirectory = lib.mkForce "data/authelia";
    };
}
