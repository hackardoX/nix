{
  config,
  lib,
  ...
}:
let
  beszelUid = 908;
  beszelGid = 908;
  beszelUser = "beszel";
  beszelGroup = "beszel";
  beszelAppDir = "/var/lib/beszel-hub";
  beszelContainerDir = "/var/lib/containers/beszel";

  hosts = config.flake.meta.reverse-proxy.hosts;
  beszelHubPort = config.flake.meta.reverse-proxy.ports.beszel;

  agentPorts = with config.flake.meta.reverse-proxy.ports; [
    beszel-agent-alerting
    beszel-agent-homepage
    beszel-agent-job-ops
    beszel-agent-reactive-resume
    beszel-agent-sure-finance
  ];

  beszelEnvFile = "/run/beszel/environment";
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
      "d ${beszelContainerDir} 0750 ${beszelUser} ${beszelGroup} -"
    ];

    # One-shot service to assemble environment file from 1Password secrets.
    # Runs before the beszel user session starts so the container can mount it.
    systemd.services.beszel-setup-env = {
      description = "Assemble Beszel Hub environment file";
      before = [ "user@${toString beszelUid}.service" ];
      requiredBy = [ "user@${toString beszelUid}.service" ];
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

    services.caddy.virtualHosts."${hosts.monitoring}" = {
      extraConfig = ''
        import auth_protected
        import reverse_proxy_common
        reverse_proxy localhost:${toString beszelHubPort}
      '';
    };

    services.onepassword-secrets.secrets = {
      beszelEmail = {
        path = "/run/secrets/beszel/email";
        reference = "op://HomeLab/Beszel/Authentication/email";
        owner = beszelUser;
        group = beszelGroup;
      };
      beszelPassword = {
        path = "/run/secrets/beszel/password";
        reference = "op://HomeLab/Beszel/Authentication/password";
        owner = beszelUser;
        group = beszelGroup;
      };
      beszelSshPrivateKey = {
        path = "/run/secrets/beszel/ssh_private_key";
        reference = "op://HomeLab/Beszel SSH Key/private key";
        owner = beszelUser;
        group = beszelGroup;
      };
      beszelSshPublicKey = {
        path = "/run/secrets/beszel/ssh_public_key";
        reference = "op://HomeLab/Beszel SSH Key/public key";
        owner = beszelUser;
        group = beszelGroup;
      };
      beszelBackupEncryptionKey = {
        path = "/run/secrets/beszel/backup_encryption_key";
        reference = "op://Homelab/Backup/Beszel/password";
        owner = beszelUser;
        group = beszelGroup;
      };
    };

    home-manager.users.${beszelUser} = {
      imports = with config.flake.modules.homeManager; [
        base
        backup
        rclone
        homelab-beszel
      ];
      home.username = beszelUser;
      home.stateVersion = "26.05";
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

  flake.modules.homeManager.homelab-beszel =
    { osConfig, ... }:
    let
      beszelPastaArgs = lib.concatStringsSep "," (
        [ "-t,${toString beszelHubPort}:8090" ]
        ++ (map (port: "-T,${toString port}:${toString port}") agentPorts)
      );
    in
    {
      xdg.configFile."containers/storage.conf".text = ''
        [storage]
        graphroot = "${beszelContainerDir}"
      '';

      services.rclone.remotes = [ "koofr" ];

      services.backup.jobs.beszel = {
        paths = [ beszelAppDir ];
        schedule = "weekly";
        retention = "extended";
        providers = [ "koofr" ];
        encryptionKey = osConfig.services.onepassword-secrets.secretPaths.beszelBackupEncryptionKey;
      };

      services.podman.enable = true;

      services.podman.containers.beszel-hub = {
        image = "ghcr.io/henrygd/beszel/beszel:0.18.7";
        autoStart = true;
        userNS = "keep-id:uid=0,gid=0";
        network = [ "pasta:${beszelPastaArgs}" ];

        environment = {
          TZ = osConfig.time.timeZone;
          APP_URL = "https://${hosts.monitoring}";
          # Password auth must stay enabled until the admin manually configures Authelia OIDC
          # in the PocketBase Admin UI. After setup, it can optionally be disabled.
          DISABLE_PASSWORD_AUTH = "false";
          USER_CREATION = "true";
        };

        volumes = [
          "${beszelAppDir}:/beszel_data"
          "${beszelSshPrivateKeySecret}:/beszel_data/id_ed25519:ro"
          "${beszelSshPublicKeySecret}:/beszel_data/id_ed25519.pub:ro"
        ];

        extraConfig = {
          Unit = {
            After = [
              "beszel-setup-env.service"
              "network-online.target"
            ];
            Wants = [ "beszel-setup-env.service" ];
          };
          Container = {
            EnvironmentFile = beszelEnvFile;
            LogDriver = "journald";
            NoNewPrivileges = true;
          };
        };
      };
    };

  # Reusable home-manager module: each service user can import this to run a beszel agent
  # container that reports host + that user's containers to the Hub.
  flake.modules.homeManager.homelab-beszel-agent =
    hmArgs@{ osConfig, ... }:
    let
      cfg = hmArgs.config.services.homelab-beszel-agent;
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
          image = "ghcr.io/henrygd/beszel/beszel-agent:0.18.7";
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
            "${beszelSshPublicKeySecret}:/run/beszel/agent-key.pub:ro"
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
