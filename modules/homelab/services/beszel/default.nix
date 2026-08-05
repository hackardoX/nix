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
  beszelDataDir = "/var/lib/data/beszel";

  hosts = config.flake.meta.reverse-proxy.hosts;
  beszelHubPort = config.flake.meta.reverse-proxy.ports.beszel;

  agentPorts = lib.mapAttrsToList (_: v: v) (
    lib.filterAttrs (n: _: lib.hasPrefix "beszel-agent-" n) config.flake.meta.reverse-proxy.ports
  );
in
{
  flake.meta.homepage.services.beszel = {
    category = "Monitoring";
    name = "Beszel";
    description = "Server Monitoring";
    icon = "sh-beszel.webp";
    href = "https://${hosts.monitoring}";
    siteMonitor = "http://localhost:${toString beszelHubPort}";
    pingPort = beszelHubPort;
    widget = config.flake.lib.beszel.mkWidget {
      systemId = "HomeLab";
    };
  };

  flake.modules.nixos.homelab-beszel = nixosArgs: {
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
      "d ${beszelDataDir} 0750 ${beszelUser} ${beszelGroup} -"
    ];

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
        mode = "0644";
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
        podman-secrets
        homelab-beszel
      ];
      home.username = beszelUser;
      home.stateVersion = "26.05";
    };

    services.beszel.agent = {
      enable = true;
      smartmon.enable = true;
      # If SMART data doesn't appear, uncomment and list your devices:
      # smartmon.deviceAllow = [ "/dev/sda" "/dev/sdb" "/dev/nvme0" ];
      environment = {
        KEY_FILE = nixosArgs.config.services.onepassword-secrets.secretPaths.beszelSshPublicKey;
        LISTEN = "127.0.0.1:${toString config.flake.meta.reverse-proxy.ports.beszel-agent-homelab}";
      };
    };

    systemd.services.beszel-agent = {
      after = [ "opnix-secrets.service" ];
      wants = [ "opnix-secrets.service" ];
    };
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
      services.rclone.remotes = [ "koofr" ];

      services.backup.jobs.beszel = {
        paths = [ beszelDataDir ];
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
          DISABLE_PASSWORD_AUTH = "true";
          USER_CREATION = "true";
        };

        secrets = {
          USER_EMAIL = osConfig.services.onepassword-secrets.secretPaths.beszelEmail;
          USER_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.beszelPassword;
        };

        volumes = [
          "${beszelDataDir}:/beszel_data"
          "${osConfig.services.onepassword-secrets.secretPaths.beszelSshPrivateKey}:/beszel_data/id_ed25519:ro"
          "${osConfig.services.onepassword-secrets.secretPaths.beszelSshPublicKey}:/beszel_data/id_ed25519.pub:ro"
        ];

        extraConfig = {
          Container = {
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
            "${osConfig.services.onepassword-secrets.secretPaths.beszelSshPublicKey}:/run/beszel/agent-key.pub:ro"
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
