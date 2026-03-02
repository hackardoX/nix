{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.sure-finance;
  defaultUser = "sure-finance";
  defaultGroup = "sure-finance";
  image = "ghcr.io/we-promise/sure:stable";

  # Network configuration
  bridgePrefix = "10.89.1";
  bridgeIP = "${bridgePrefix}.1";
  bridgeSubnet = "${bridgePrefix}.0/28";
  # webContainerIP = "${bridgePrefix}.2";

  # Environment variables for both web and worker containers
  containerEnv = {
    RAILS_ENV = "production";
    RAILS_LOG_TO_STDOUT = "true";
    SELF_HOSTED = "true";

    # Database configuration
    POSTGRES_USER = cfg.database.user;
    POSTGRES_DB = cfg.database.name;
    DB_HOST = cfg.database.host;
    DB_PORT = toString cfg.database.port;

    # SSL configuration
    RAILS_FORCE_SSL = lib.boolToString cfg.forceSSL;
    RAILS_ASSUME_SSL = lib.boolToString cfg.assumeSSL;

    # AI configuration
    OPENAI_MODEL = cfg.openai.model;
    OPENAI_URI_BASE = cfg.openai.baseUrl;
  };

in
{
  options.services.sure-finance = {
    enable = lib.mkEnableOption "Sure Finance personal finance application";

    # Domain and port configuration
    domain = lib.mkOption {
      type = lib.types.str;
      example = "finance.example.com";
      description = lib.mdDoc "Domain name for the application";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = lib.mdDoc "Port for the web server to bind to";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = defaultUser;
      description = lib.mdDoc "User running sure-finance containers";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = defaultGroup;
      description = lib.mdDoc "Group running sure-finance containers";
    };

    forceSSL = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc "Whether to force SSL/HTTPS";
    };

    assumeSSL = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = lib.mdDoc "Whether to assume the app is behind an SSL proxy";
    };

    openai = {
      baseUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = lib.mdDoc ''
          Optional base url value used for custom OpenAI compatible LLM.
        '';
      };

      model = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = lib.mdDoc ''
          Optional model to use.
        '';
      };
    };

    # Secrets configuration
    secrets = {
      secretKeyBasePath = lib.mkOption {
        type = lib.types.path;
        description = lib.mdDoc ''
          Path to a file containing the SECRET_KEY_BASE value.

          The file should contain only the secret value (128 hex characters).
          Generate with: `openssl rand -hex 64`
        '';
      };

      postgresPasswordPath = lib.mkOption {
        type = lib.types.path;
        description = lib.mdDoc ''
          Path to a file containing the POSTGRES_PASSWORD value.
          The file should contain only the password value.
        '';
      };

      redisPasswordPath = lib.mkOption {
        type = lib.types.path;
        description = lib.mdDoc ''
          Path to a file containing the Redis password.
          The file should contain only the password value.
        '';
      };

      enableBankingAppIdPath = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = lib.mdDoc ''
          Path to a file containing the ENABLE_BANKING_APP_ID value.
        '';
      };

      openAiTokenPath = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = lib.mdDoc ''
          Optional path to a file containing the OPENAI_ACCESS_TOKEN value.

          Only needed if you want to use AI features.
        '';
      };

    };

    # State directory for persistent storage
    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/sure-finance";
      description = lib.mdDoc "Directory for persistent application data";
    };

    # Database configuration
    database = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc "Whether to enable local PostgreSQL database";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "host.containers.internal";
        # default = bridgeIP;
        description = lib.mdDoc "PostgreSQL host";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 5432;
        description = lib.mdDoc "PostgreSQL port";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "sure_finance";
        description = lib.mdDoc "PostgreSQL user";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "sure_finance";
        description = lib.mdDoc "PostgreSQL database name";
      };
    };

    # Redis configuration
    redis = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc "Whether to enable local Redis instance";
      };

      host = lib.mkOption {
        type = lib.types.str;
        # default = bridgeIP;
        default = "host.containers.internal";
        description = lib.mdDoc "Redis host";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 6379;
        description = lib.mdDoc "Redis port";
      };
    };

    # Nginx reverse proxy
    nginx = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc "Whether to enable Nginx reverse proxy";
      };

      enableACME = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc "Whether to enable automatic SSL certificate via ACME/Let's Encrypt";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable container runtime
    virtualisation.podman = {
      enable = lib.mkDefault true;
      dockerCompat = lib.mkDefault true;
    };

    # Create user and group if needed
    users.users = {
      ${defaultUser} = lib.mkIf (cfg.user == defaultUser) {
        isSystemUser = true;
        inherit (cfg) group;
        description = "Sure Finance service user";
        home = cfg.stateDir;
        linger = false;
        subUidRanges = [
          {
            startUid = 100000;
            count = 65536;
          }
        ];
        subGidRanges = [
          {
            startGid = 100000;
            count = 65536;
          }
        ];
      };
    };
    users.groups.${cfg.group} = {
      members = [
        "postgres"
        "redis-sure-finance"
        defaultUser
      ];
    };

    # PostgreSQL database (if enabled)
    services.postgresql = lib.mkIf cfg.database.enable {
      enable = lib.mkDefault true;
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensureDBOwnership = true;
        }
      ];
      # Enable password authentication for the container
      authentication = ''
        # TYPE  DATABASE               USER                   ADDRESS                 METHOD
        local   ${cfg.database.name}   ${cfg.database.user}                           md5
        host    ${cfg.database.name}   ${cfg.database.user}   127.0.0.1/32            md5
        host    ${cfg.database.name}   ${cfg.database.user}   ::1/128                 md5
        host    ${cfg.database.name}   ${cfg.database.user}   ${bridgeSubnet}         md5
      '';

      # Enable TCP/IP connections
      enableTCPIP = lib.mkDefault true;
    };

    # Redis server (if enabled)
    services.redis.servers.sure-finance = lib.mkIf cfg.redis.enable {
      enable = true;
      inherit (cfg.redis) port;
      # bind = bridgeIP;
      requirePassFile = cfg.secrets.redisPasswordPath;
      settings = {
        # Security: disable dangerous commands
        protected-mode = "yes";
        rename-command = [
          "FLUSHALL ''"
          "FLUSHDB ''"
          "CONFIG ''"
          "DEBUG ''"
        ];
      };
    };

    # Nginx reverse proxy (if enabled)
    services.nginx = lib.mkIf cfg.nginx.enable {
      enable = lib.mkDefault true;

      # Security headers
      appendHttpConfig = lib.mkDefault ''
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self';" always;
      '';

      virtualHosts.${cfg.domain} = {
        forceSSL = lib.mkDefault cfg.nginx.enableACME;
        enableACME = lib.mkDefault cfg.nginx.enableACME;

        locations."/" = {
          # proxyPass = "http://${webContainerIP}:${toString cfg.port}";
          proxyPass = "http://127.0.0.1:${toString cfg.port}";
          proxyWebsockets = true;

          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;

            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
          '';
        };
      };
    };

    # OCI containers for Sure Finance
    virtualisation.oci-containers = {
      backend = "podman";

      containers = {
        # Web server container
        sure-finance-web = {
          inherit image;

          ports = [ "127.0.0.1:${toString cfg.port}:3000" ];

          environment = containerEnv;

          volumes = [
            "${cfg.stateDir}/storage:/rails/storage"
          ];

          inherit (cfg) user;
          podman.user = cfg.user;

          extraOptions = [
            "--add-host=host.containers.internal:host-gateway"
            "--cap-drop=ALL"
            "--network=sure-finance"
            # "--ip=${webContainerIP}"
            "--security-opt=no-new-privileges"
            "--secret=sure-finance-secret-key,type=env,target=SECRET_KEY_BASE"
            "--secret=sure-finance-db-password,type=env,target=POSTGRES_PASSWORD"
            "--secret=sure-finance-redis-url,type=env,target=REDIS_URL"
          ]
          ++ lib.optionals (cfg.secrets.enableBankingAppIdPath != null) [
            "--secret=sure-finance-enable-banking-app-id,type=env,target=ENABLE_BANKING_APP_ID"
          ]
          ++ lib.optionals (cfg.secrets.openAiTokenPath != null) [
            "--secret=sure-finance-openai-token,type=env,target=OPENAI_ACCESS_TOKEN"
          ];
        };

        # Background worker container
        sure-finance-worker = {
          inherit image;

          cmd = [
            "bundle"
            "exec"
            "sidekiq"
          ];

          environment = containerEnv;

          volumes = [
            "${cfg.stateDir}/storage:/rails/storage"
          ];

          inherit (cfg) user;
          podman.user = cfg.user;

          extraOptions = [
            "--add-host=host.containers.internal:host-gateway"
            "--cap-drop=ALL"
            "--network=sure-finance"
            "--security-opt=no-new-privileges"
            "--secret=sure-finance-secret-key,type=env,target=SECRET_KEY_BASE"
            "--secret=sure-finance-db-password,type=env,target=POSTGRES_PASSWORD"
            "--secret=sure-finance-redis-url,type=env,target=REDIS_URL"
          ]
          ++ lib.optionals (cfg.secrets.enableBankingAppIdPath != null) [
            "--secret=sure-finance-enable-banking-app-id,type=env,target=ENABLE_BANKING_APP_ID"
          ]
          ++ lib.optionals (cfg.secrets.openAiTokenPath != null) [
            "--secret=sure-finance-openai-token,type=env,target=OPENAI_ACCESS_TOKEN"
          ];
        };
      };
    };

    # Ensure proper service ordering
    systemd.services = {
      sure-finance-db-init =
        let
          serviceDeps = [
            "postgresql.service"
            "secrets-sure-finance.service"
          ];
        in
        lib.mkIf cfg.database.enable {
          description = "Initialize Sure Finance database password";
          after = serviceDeps;
          requires = serviceDeps;
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "postgres";
            Group = cfg.group;
          };

          script = ''
            set -euo pipefail

            until ${config.services.postgresql.package}/bin/pg_isready -q; do
              echo "Waiting for PostgreSQL..."
              sleep 1
            done

            if [ ! -f "${cfg.secrets.postgresPasswordPath}" ]; then
              echo "ERROR: Password file ${cfg.secrets.postgresPasswordPath} not found!"
              exit 1
            fi

            DB_PASS=$(cat "${cfg.secrets.postgresPasswordPath}")

            echo "Updating password for user ${cfg.database.user}..."

            export NEW_PASS="$DB_PASS"
            ${config.services.postgresql.package}/bin/psql -v ON_ERROR_STOP=1 <<EOF
              DO \$$
              BEGIN
                EXECUTE format('ALTER USER %I WITH PASSWORD %L', '${cfg.database.user}', '${"\$NEW_PASS"}');
              END
              \$$;
            EOF

            echo "✓ Password synchronization complete."
          '';
        };

      podman-sure-finance-web =
        let
          serviceDeps = [
            "secrets-sure-finance.service"
          ]
          ++ lib.optionals cfg.database.enable [
            "postgresql.service"
            "sure-finance-db-init.service"
          ]
          ++ lib.optionals cfg.redis.enable [ "redis-sure-finance.service" ];
        in
        {
          after = serviceDeps;
          requires = serviceDeps;
        };

      podman-sure-finance-worker =
        let
          serviceDeps = [
            "secrets-sure-finance.service"
          ]
          ++ lib.optionals cfg.database.enable [
            "postgresql.service"
            "sure-finance-db-init.service"
          ]
          ++ lib.optionals cfg.redis.enable [ "redis-sure-finance.service" ]
          ++ [ "podman-sure-finance-web.service" ];
        in
        {
          after = serviceDeps;
          requires = serviceDeps;
        };

      redis-sure-finance =
        let
          serviceDeps = [
            "secrets-sure-finance.service"
            "podman-network-sure-finance.service"
          ];
        in
        {
          after = serviceDeps;
          requires = serviceDeps;
        };

      podman-network-sure-finance = {
        description = "Create Sure Finance Podman network";
        wantedBy = [ "multi-user.target" ];
        after = [ "NetworkManager-wait-online.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = cfg.user;
          Group = cfg.group;
        };
        script = ''
          if ! ${pkgs.podman}/bin/podman network exists sure-finance 2>/dev/null; then
            ${pkgs.podman}/bin/podman network create \
              --interface-name sf-br0 \  
              --subnet ${bridgeSubnet} \
              sure-finance
              # --gateway ${bridgeIP} \
          fi
        '';
      };

      secrets-sure-finance = {
        description = "Create Podman secrets for Sure Finance";
        after = [
          "opnix-secrets.service"
        ];
        bindsTo = [
          "opnix-secrets.service"
        ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = cfg.user;
          Group = cfg.group;
        };

        script = ''
          # Wait for secret files to exist (with timeout)
          wait_for_file() {
            local file=$1
            local timeout=120
            local elapsed=0
            
            while [ ! -f "$file" ]; do
              if [ $elapsed -ge $timeout ]; then
                echo "Error: Timeout waiting for secret file: $file"
                echo "Please ensure your secrets management system is configured correctly."
                exit 1
              fi
              echo "Waiting for secret file: $file ($${elapsed}s/$${timeout}s)"
              sleep 1
              elapsed=$((elapsed + 1))
            done
            
            echo "Found secret file: $file"
          }

          # Wait for all required secret files
          wait_for_file "${cfg.secrets.secretKeyBasePath}"
          wait_for_file "${cfg.secrets.postgresPasswordPath}"
          wait_for_file "${cfg.secrets.redisPasswordPath}"

          ${lib.optionalString (cfg.secrets.enableBankingAppIdPath != null) ''
            wait_for_file "${cfg.secrets.enableBankingAppIdPath}"
          ''}
          ${lib.optionalString (cfg.secrets.openAiTokenPath != null) ''
            wait_for_file "${cfg.secrets.openAiTokenPath}"
          ''}

          # Helper function to create or update a Podman secret
          update_secret() {
            local secret_name=$1
            local secret_value=$2
            
            # Remove old secret if it exists (ignore errors)
            ${pkgs.podman}/bin/podman secret rm "$secret_name" 2>/dev/null || true
            
            # Create new secret from file
            echo -n "$secret_value" | ${pkgs.podman}/bin/podman secret create "$secret_name" -
            
            echo "Created Podman secret: $secret_name"
          }

          # Create secrets from the configured paths
          update_secret "sure-finance-secret-key" $(cat "${cfg.secrets.secretKeyBasePath}")
          update_secret "sure-finance-db-password" $(cat "${cfg.secrets.postgresPasswordPath}")
          update_secret "sure-finance-redis-url" "redis://:$(cat "${cfg.secrets.redisPasswordPath}")@${cfg.redis.host}:${toString cfg.redis.port}/1"

          ${lib.optionalString (cfg.secrets.enableBankingAppIdPath != null) ''
            update_secret "sure-finance-enable-banking-app-id" $(cat "${cfg.secrets.enableBankingAppIdPath}")
          ''}
          ${lib.optionalString (cfg.secrets.openAiTokenPath != null) ''
            update_secret "sure-finance-openai-token" $(cat "${cfg.secrets.openAiTokenPath}")
          ''}
        '';

        # Clean up secrets when service is stopped
        preStop = ''
          ${pkgs.podman}/bin/podman secret rm sure-finance-secret-key 2>/dev/null || true
          ${pkgs.podman}/bin/podman secret rm sure-finance-db-password 2>/dev/null || true
          ${pkgs.podman}/bin/podman secret rm sure-finance-redis-url 2>/dev/null || true
          ${lib.optionalString (cfg.secrets.enableBankingAppIdPath != null) ''
            ${pkgs.podman}/bin/podman secret rm sure-finance-enable-banking-app-id 2>/dev/null || true
          ''}
          ${lib.optionalString (cfg.secrets.openAiTokenPath != null) ''
            ${pkgs.podman}/bin/podman secret rm sure-finance-openai-token 2>/dev/null || true
          ''}
        '';
      };
    };

    # networking = {
    # networkmanager.ensureProfiles.profiles = {
    #   sf-br0 = {
    #     connection = {
    #       id = "sf-br0";
    #       type = "bridge";
    #       interface-name = "sf-br0";
    #       autoconnect = true;
    #     };
    #     bridge = {
    #       stp = "false";
    #     };
    #     ipv4 = {
    #       method = "manual";
    #       addresses = "${bridgeIP}/24";
    #     };
    #   };
    #   sf-br0-slave = {
    #     connection = {
    #       id = "sf-br0-dummy";
    #       type = "dummy";
    #       interface-name = "sf-br0-dummy";
    #       master = "sf-br0";
    #       slave-type = "bridge";
    #     };
    #   };
    # };
    # firewall = {
    #   interfaces.sf-br0 = {
    #     allowedTCPPorts = [
    #       5432
    #       6379
    #     ];
    # allowedUDPPorts = [ 53 ];
    # };

    # extraCommands = ''
    #   iptables -t nat -A POSTROUTING -i sf-br0 ! -o sf-br0 -j MASQUERADE
    # '';
    #
    # extraStopCommands = ''
    #   iptables -t nat -D POSTROUTING -i sf-br0 ! -o sf-br0 -j MASQUERADE || true
    # '';
    # };
    # };

    # Create state directory with proper permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.stateDir}/storage 0750 ${cfg.user} ${cfg.group} - -"
    ];
  };
}
