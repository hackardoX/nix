{
  config,
  lib,
  pkgs,
  ...
}:
let
  beszelUid = 908;
  beszelGid = 908;
  beszelUser = "beszel";
  beszelGroup = "beszel";
  beszelAppDir = "/var/lib/beszel-hub";

  hosts = config.flake.meta.reverse-proxy.hosts;
  beszelHubPort = config.flake.meta.reverse-proxy.ports.beszel;
  beszelOidcClientId = config.flake.meta.oidc-clients.beszel.clientId;

  # Agent ports are defined per-service; this module only provides the agent home-manager module.
  # The hub connects to agents on 127.0.0.1 via SSH keys.

  beszelEnvFile = "/run/beszel/environment";
  beszelEmailSecret = "/run/secrets/beszel/email";
  beszelPasswordSecret = "/run/secrets/beszel/password";
  beszelBackupKeySecret = "/run/secrets/beszel/backup_encryption_key";
in
{
  flake.homepage.services.beszel = {
    category = "Monitoring";
    name = "Beszel";
    description = "Server Monitoring";
    icon = "beszel.png";
    href = "https://${hosts.monitoring}";
    siteMonitor = "http://localhost:${toString beszelHubPort}";
    pingPort = beszelHubPort;
  };

  flake.modules.nixos.homelab-beszel = {
    users.users.${beszelUser} = {
      uid = beszelUid;
      isSystemUser = true;
      group = beszelGroup;
      extraGroups = [
        "homelab-users"
        "rclone"
      ];
      createHome = true;
      home = "/var/lib/${beszelUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${beszelGroup} = {
      gid = beszelGid;
    };

    systemd.tmpfiles.rules = [
      "d ${beszelAppDir} 0750 ${beszelUser} ${beszelGroup} -"
    ];

    # Override the native beszel-hub service to run as our static user instead of DynamicUser.
    # This lets us add home-manager (backup, rclone) for the beszel user.
    systemd.services.beszel-hub = {
      after = [ "opnix-secrets.service" ];
      wants = [ "opnix-secrets.service" ];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkForce beszelUser;
        Group = lib.mkForce beszelGroup;
        PrivateUsers = lib.mkForce false;
        StateDirectory = lib.mkForce null;
        WorkingDirectory = lib.mkForce beszelAppDir;
        ReadWritePaths = lib.mkForce [ beszelAppDir ];
        EnvironmentFile = lib.mkIf (builtins.pathExists beszelEnvFile) beszelEnvFile;
      };
    };

    services.beszel.hub = {
      enable = true;
      port = beszelHubPort;
      dataDir = beszelAppDir;
      environment = {
        APP_URL = "https://${hosts.monitoring}";
        DISABLE_PASSWORD_AUTH = "true";
        USER_CREATION = "true";
      };
    };

    # One-shot service to assemble environment file from 1Password secrets
    systemd.services.beszel-setup-env = {
      description = "Assemble Beszel Hub environment file";
      before = [ "beszel-hub.service" ];
      requiredBy = [ "beszel-hub.service" ];
      after = [ "opnix-secrets.service" ];
      wants = [ "opnix-secrets.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
        set -e
        mkdir -p /run/beszel
        {
          echo "USER_EMAIL=$(cat ${beszelEmailSecret})"
          echo "USER_PASSWORD=$(cat ${beszelPasswordSecret})"
        } > ${beszelEnvFile}
        chown ${beszelUser}:${beszelGroup} ${beszelEnvFile}
        chmod 400 ${beszelEnvFile}
      '';
    };

    # Extract the Hub's SSH public key so agents can authenticate it.
    # Runs after the Hub has started (and generated its Ed25519 keypair).
    systemd.services.beszel-agent-keys = {
      description = "Extract Beszel Hub SSH public key for agents";
      after = [ "beszel-hub.service" ];
      requires = [ "beszel-hub.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
        set -e
        mkdir -p /run/beszel
        # Wait up to 30 seconds for the Hub to generate its keypair
        for i in $(seq 1 30); do
          if [ -f ${beszelAppDir}/id_ed25519 ]; then
            break
          fi
          sleep 1
        done
        if [ ! -f ${beszelAppDir}/id_ed25519 ]; then
          echo "Timeout waiting for beszel-hub SSH key" >&2
          exit 1
        fi
        ${pkgs.openssh}/bin/ssh-keygen -y -f ${beszelAppDir}/id_ed25519 > /run/beszel/agent-key.pub
        chmod 644 /run/beszel/agent-key.pub
      '';
    };

    services.caddy.virtualHosts."${hosts.monitoring}" = {
      extraConfig = ''
        import auth_protected
        import reverse_proxy_common
        reverse_proxy localhost:${toString beszelHubPort}
      '';
    };

    services.onepassword-secrets.secrets = {
      beszelEmail = {
        path = beszelEmailSecret;
        reference = "op://HomeLab/Beszel/Authentication/email";
        owner = beszelUser;
        group = beszelGroup;
      };
      beszelPassword = {
        path = beszelPasswordSecret;
        reference = "op://HomeLab/Beszel/Authentication/password";
        owner = beszelUser;
        group = beszelGroup;
      };
      beszelBackupEncryptionKey = {
        path = beszelBackupKeySecret;
        reference = "op://Homelab/Backup/Beszel/password";
        owner = beszelUser;
        group = beszelGroup;
      };
    };

    home-manager.users.${beszelUser} = {
      home.username = beszelUser;
      home.stateVersion = "26.05";
      imports = with config.flake.modules.homeManager; [
        base
        backup
        rclone
      ];
      services.rclone.remotes = [ "koofr" ];
      services.backup.jobs.beszel = {
        paths = [ beszelAppDir ];
        schedule = "weekly";
        retention = "extended";
        providers = [ "koofr" ];
        encryptionKey = config.services.onepassword-secrets.secretPaths.beszelBackupEncryptionKey;
      };
    };

    boot.initrd.impermanence.persist.directories = [
      {
        directory = beszelAppDir;
        user = beszelUser;
        group = beszelGroup;
        mode = "0750";
      }
    ];
  };

  # Reusable home-manager module: each service user can import this to run a beszel agent
  # container that reports host + that user's containers to the Hub.
  flake.modules.homeManager.homelab-beszel-agent =
    hmArgs:
    let
      cfg = hmArgs.config.services.homelab-beszel-agent;
      osConfig = hmArgs.osConfig;
    in
    {
      options.services.homelab-beszel-agent = {
        enable = lib.mkEnableOption "beszel agent for this user's podman containers";
        port = lib.mkOption {
          type = lib.types.port;
          description = "TCP port for the agent SSH listener (on 127.0.0.1). Must be unique per host.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.podman.enable = true;

        services.podman.containers.homelab-beszel-agent = {
          image = "henrygd/beszel-agent:latest";
          autoStart = true;
          userNS = "keep-id";
          ports = [ "127.0.0.1:${toString cfg.port}:45876" ];

          environment = {
            TZ = osConfig.time.timeZone;
            LISTEN = "0.0.0.0:45876";
            DOCKER_HOST = "unix:///run/podman/podman.sock";
            KEY_FILE = "/run/beszel/agent-key.pub";
          };

          volumes = [
            "%t/podman/podman.sock:/run/podman/podman.sock:ro"
            "/run/beszel/agent-key.pub:/run/beszel/agent-key.pub:ro"
          ];

          extraConfig.Container = {
            LogDriver = "journald";
            SecurityLabelDisable = true;
            NoNewPrivileges = true;
          };
        };
      };
    };
}
