{ config, ... }:
let
  inherit (config.flake.lib.backup) retentionPresets;
  koofrEmail = config.flake.meta.users.hackardo.email;
in
{
  # Keeps the storage credentials away from the services that make backups.
  #
  # Without it every service user holds the Koofr account password, so one
  # compromised service can delete or overwrite every repository. With it, only
  # short-lived system units hold the password:
  #
  #   - backup-gateway-<job>: one per backup job, socket activated. It serves
  #     `koofr:backup/<job>` to restic over a unix socket in append-only mode
  #     (new files only; existing files cannot be overwritten, and only locks
  #     can be deleted). The socket belongs to the job user's group, so a service
  #     can reach its own repository and no other.
  #   - backup-prune-<job>: a weekly timer that applies the retention policy,
  #     which the append-only socket refuses.
  #
  # This stops a compromised service. It does not stop root on this host, who
  # can read the password and the repository keys.
  flake.modules.nixos.backup-gateway =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.backup-gateway;

      koofrPassword = config.sops.secrets."rclone/koofr/password".path;

      # Every restic job of every home-manager user.
      jobs = lib.concatLists (
        lib.mapAttrsToList (
          user: userCfg:
          lib.mapAttrsToList (name: job: {
            inherit name user job;
            group = config.users.users.${user}.group;
          }) (userCfg.services.backup.jobs or { })
        ) (config.home-manager.users or { })
      );

      remote =
        job: "koofr:backup/${if job.job.destination != null then job.job.destination else job.name}";

      # rclone takes the remote definition from the environment, so no config
      # file with the password is ever written. The password is read from the
      # unit's credentials directory.
      rcloneEnv = ''
        export RCLONE_CONFIG=/dev/null
        export RCLONE_CONFIG_KOOFR_TYPE=koofr
        export RCLONE_CONFIG_KOOFR_ENDPOINT=https://app.koofr.net
        export RCLONE_CONFIG_KOOFR_USER=${lib.escapeShellArg koofrEmail}
        RCLONE_CONFIG_KOOFR_PASSWORD="$(tr -d '\n' < "$CREDENTIALS_DIRECTORY/koofr-password" | rclone obscure -)"
        export RCLONE_CONFIG_KOOFR_PASSWORD
      '';

      sandbox = {
        DynamicUser = true;
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
        UMask = "0077";
      };
    in
    {
      options.services.backup-gateway.socketDir = lib.mkOption {
        type = lib.types.path;
        default = "/run/backup-gateway";
        description = ''
          Directory holding one append-only restic socket per backup job
          (`<job>.sock`). Home-manager backup jobs use it automatically.
        '';
      };

      config = lib.mkIf (jobs != [ ]) {
        systemd.sockets = lib.listToAttrs (
          map (
            j:
            lib.nameValuePair "backup-gateway-${j.name}" {
              description = "Append-only restic socket for ${j.name}";
              wantedBy = [ "sockets.target" ];
              socketConfig = {
                ListenStream = "${cfg.socketDir}/${j.name}.sock";
                SocketUser = "root";
                SocketGroup = j.group;
                SocketMode = "0660";
              };
            }
          ) jobs
        );

        systemd.services =
          lib.listToAttrs (
            map (
              j:
              lib.nameValuePair "backup-gateway-${j.name}" {
                description = "Append-only restic gateway for ${j.name}";
                wants = [ "network-online.target" ];
                after = [ "network-online.target" ];
                path = [
                  pkgs.coreutils
                  pkgs.rclone
                ];
                script = ''
                  ${rcloneEnv}
                  exec rclone serve restic --append-only ${lib.escapeShellArg (remote j)}
                '';
                serviceConfig = sandbox // {
                  LoadCredential = "koofr-password:${koofrPassword}";
                };
              }
            ) jobs
          )
          // lib.listToAttrs (
            map (
              j:
              lib.nameValuePair "backup-prune-${j.name}" {
                description = "Apply the retention policy to the ${j.name} backups";
                wants = [ "network-online.target" ];
                after = [ "network-online.target" ];
                path = [
                  pkgs.coreutils
                  pkgs.rclone
                  pkgs.restic
                ];
                environment = {
                  RESTIC_REPOSITORY = "rclone:${remote j}";
                  RESTIC_CACHE_DIR = "%C/backup-prune-${j.name}";
                };
                script = ''
                  ${rcloneEnv}
                  export RESTIC_PASSWORD_FILE="$CREDENTIALS_DIRECTORY/repository-key"
                  # Stale locks of backups that were killed would block the prune.
                  restic unlock
                  restic forget --prune ${lib.concatStringsSep " " retentionPresets.${j.job.retention}}
                '';
                serviceConfig = sandbox // {
                  Type = "oneshot";
                  CacheDirectory = "backup-prune-${j.name}";
                  LoadCredential = [
                    "koofr-password:${koofrPassword}"
                    "repository-key:${j.job.encryptionKey}"
                  ];
                };
              }
            ) jobs
          );

        systemd.timers = lib.listToAttrs (
          map (
            j:
            lib.nameValuePair "backup-prune-${j.name}" {
              description = "Weekly retention for the ${j.name} backups";
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = "Sun 05:00";
                RandomizedDelaySec = "1h";
                Persistent = true;
              };
            }
          ) jobs
        );
      };
    };
}
