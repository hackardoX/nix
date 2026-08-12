{ config, lib, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  hosts = config.flake.meta.reverse-proxy.hosts;
  authDomain = hosts.auth;
  autheliaPort = config.flake.meta.reverse-proxy.ports.authelia;
in
{
  flake.meta = {
    oidc-clients = {
      beszel = {
        clientId = "beszel";
        clientName = "Monitoring";
        policy = "two_factor";
        redirectUris = [ "https://${hosts.monitoring}/api/oauth2-redirect" ];
        secretName = "autheliaBeszelOidcSecret";
      };
      immich = {
        clientId = "immich";
        clientName = "Immich";
        policy = "two_factor";
        redirectUris = [
          "https://${hosts.immich}/auth/login-callback"
          "https://${hosts.immich}/api/oauth/mobile"
        ];
        secretName = "autheliaImmichOidcSecret";
      };
      tandoor = {
        clientId = "tandoor";
        clientName = "Tandoor Recipes";
        policy = "two_factor";
        redirectUris = [ "https://${hosts.recipes}/accounts/oidc/authelia/login/callback/" ];
        secretName = "autheliaTandoorOidcSecret";
      };
      reactive-resume = {
        clientId = "reactive-resume";
        clientName = "Reactive Resume";
        policy = "two_factor";
        redirectUris = [ "https://${hosts.rxresume}/api/auth/oauth2/callback/custom" ];
        secretName = "autheliaReactiveResumeOidcSecret";
      };
      sure-finance = {
        clientId = "sure-finance";
        clientName = "Sure Finance";
        policy = "two_factor";
        redirectUris = [ "https://${hosts.finance}/auth/openid_connect/callback" ];
        secretName = "autheliaSureFinanceOidcSecret";
        extraYamlLines = [
          ''token_endpoint_auth_method: "client_secret_basic"''
          "require_pkce: true"
          ''pkce_challenge_method: "S256"''
          ''access_token_signed_response_alg: "none"''
          ''userinfo_signed_response_alg: "none"''
        ];
      };
      dawarich = {
        clientId = "dawarich";
        clientName = "Dawarich";
        policy = "two_factor";
        redirectUris = [ "https://${hosts.timeline}/users/auth/openid_connect/callback" ];
        secretName = "autheliaDawarichOidcSecret";
        extraYamlLines = [
          ''token_endpoint_auth_method: "client_secret_basic"''
        ];
      };
    };
  };

  flake.modules.nixos.homelab-security =
    nixosArgs@{ pkgs, ... }:
    let
      autheliaDataDir = "/var/lib/data/authelia";
      hashedSecretsDir = "${autheliaDataDir}/hashed-oidc-secrets";

      oidcClients = lib.mapAttrsToList (name: client: {
        inherit name;
        secretPath = nixosArgs.config.services.onepassword-secrets.secretPaths.${client.secretName};
      }) config.flake.meta.oidc-clients;

      oidcClientsYaml =
        let
          indentClientYaml =
            name: client:
            lib.concatMapStringsSep "\n" (line: "      ${line}") (
              lib.init (lib.splitString "\n" (config.flake.lib.authelia.mkOidcClientYaml name client))
            );
        in
        ''
          identity_providers:
            oidc:
              clients:
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList indentClientYaml config.flake.meta.oidc-clients)}
        '';

      oidcClientsFile = builtins.toFile "oidc_clients.yaml" oidcClientsYaml;
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
                endpoints = {
                  authz = {
                    forward-auth = {
                      implementation = "ForwardAuth";
                      authn_strategies = [
                        { name = "CookieSession"; }
                      ];
                    };
                  };
                };
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
                file.path = nixosArgs.config.services.onepassword-secrets.secretPaths.autheliaUsersFile;
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
                    inherit domain;
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
                    inherit domain;
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
                  allowed_origins = config.flake.lib.authelia.mkAllowedOrigins config.flake.meta.oidc-clients;
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
            settingsFiles = [ oidcClientsFile ];
          };
        };

        timesyncd.enable = false;
        chrony.enable = true;

        caddy = {
          virtualHosts."${authDomain}" = {
            extraConfig = ''
              import reverse_proxy_common
              reverse_proxy localhost:${toString autheliaPort}
            '';
          };

          extraConfig = lib.mkAfter ''
            (auth_protected) {
              forward_auth localhost:${toString autheliaPort} {
                uri /api/authz/forward-auth
                copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
              }
            }
          '';
        };
      };

      users.users.${config.flake.meta.users.authelia.name}.extraGroups = [ "homelab-users" ];

      systemd.tmpfiles.rules = [
        "d ${hashedSecretsDir} 0750 ${config.flake.meta.users.authelia.name} ${config.flake.meta.users.authelia.primaryGroup} -"
      ];

      systemd.services.authelia-init = {
        description = "Hash OIDC client secrets for Authelia";
        before = [ "authelia-default.service" ];
        requiredBy = [ "authelia-default.service" ];
        after = [ "opnix-secrets.service" ];
        wants = [ "opnix-secrets.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = config.flake.meta.users.authelia.name;
          Group = config.flake.meta.users.authelia.primaryGroup;
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
        );
      };

      systemd.services.authelia-default.serviceConfig.StateDirectory = lib.mkForce "data/authelia";
    };
}
