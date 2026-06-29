{
  config,
  lib,
  ...
}:
{
  flake.modules.homeManager.base =
    { pkgs, ... }@hmArgs:
    let
      cfg = hmArgs.config.services.rclone-sync;
      rcloneRemotes = hmArgs.config.programs.rclone.remotes or { };

      isLinux = pkgs.stdenv.isLinux;
      isDarwin = pkgs.stdenv.isDarwin;

      mkLaunchdInterval =
        schedule:
        if schedule == null then
          null
        else if schedule == "minutely" then
          60
        else if schedule == "hourly" then
          3600
        else if schedule == "daily" then
          86400
        else if schedule == "weekly" then
          604800
        else if schedule == "monthly" then
          2592000
        else
          let
            parsed = builtins.match "\\*:0/([0-9]+)" schedule;
          in
          if parsed != null then 60 * builtins.fromJSON (builtins.head parsed) else 60;

      mkScript =
        jobName: jobCfg: provider:
        let
          serviceName = jobName;

          dest = if jobCfg.destination != null then jobCfg.destination else jobName;
          remotePath =
            if jobCfg.encrypted then
              "${config.flake.lib.rclone.mkCryptRemoteName jobName provider}:${dest}"
            else
              "${provider}:${dest}";

          mkCommonFlags =
            exclude: maxDelete: direction:
            lib.optionals (direction != "copy" && maxDelete != null) [
              "--max-delete"
              (toString maxDelete)
            ]
            ++ lib.concatMap (p: [
              "--exclude"
              p
            ]) exclude;

          bisyncCmd = "rclone bisync ${
            lib.escapeShellArgs (
              [
                jobCfg.localPath
                remotePath
                "--conflict-resolve"
                "newer"
              ]
              ++ mkCommonFlags jobCfg.exclude jobCfg.maxDelete "bisync"
            )
          }";

          copyCmd = "rclone copy ${
            lib.escapeShellArgs (
              [
                jobCfg.localPath
                remotePath
              ]
              ++ mkCommonFlags jobCfg.exclude jobCfg.maxDelete "copy"
            )
          }";

          syncCmd = "rclone sync ${
            lib.escapeShellArgs (
              [
                jobCfg.localPath
                remotePath
              ]
              ++ mkCommonFlags jobCfg.exclude jobCfg.maxDelete "sync"
            )
          }";
        in
        pkgs.writeShellApplication {
          name = "rclone-sync-${serviceName}";
          runtimeInputs = [
            pkgs.rclone
            pkgs.flock
          ];
          text = ''

            SENTINEL="''${XDG_STATE_HOME:-$HOME/.local/state}/rclone-sync/${serviceName}.initialized"
            mkdir -p ${lib.escapeShellArg jobCfg.localPath}

            exec {lock_fd}>${lib.escapeShellArg jobCfg.localPath}/.rclone-sync.lock
            flock $lock_fd

            ${
              if jobCfg.direction == "bisync" then
                ''
                  if [ ! -f "$SENTINEL" ]; then
                    echo "rclone-sync: first run, performing initial resync..."
                    ${bisyncCmd} --resync
                    mkdir -p "$(dirname "$SENTINEL")"
                    touch "$SENTINEL"
                  else
                    ${bisyncCmd}
                  fi
                ''
              else if jobCfg.direction == "copy" then
                ''
                  ${copyCmd}
                ''
              else
                ''
                  ${syncCmd}
                ''
            }
          '';
        };

      buildServices = lib.concatMapAttrs (
        jobName: jobCfg:
        lib.listToAttrs (
          map (
            provider:
            let
              serviceName = jobName;
              script = mkScript jobName jobCfg provider;
            in
            {
              name = "rclone-sync-${serviceName}";
              value = {
                Unit = {
                  Description = "rclone sync: ${serviceName}";
                  After = [ "network-online.target" ];
                  Wants = [ "network-online.target" ];
                };
                Service = {
                  Type = "oneshot";
                  ExecStart = "${script}/bin/rclone-sync-${serviceName}";
                };
              };
            }
          ) jobCfg.providers
        )
      ) cfg.jobs;

      buildTimers = lib.concatMapAttrs (
        jobName: jobCfg:
        lib.optionalAttrs (jobCfg.schedule != null) (
          lib.listToAttrs (
            map (
              provider:
              let
                serviceName = jobName;
              in
              {
                name = "rclone-sync-${serviceName}";
                value = {
                  Unit = {
                    Description = "rclone sync timer: ${serviceName}";
                  };
                  Timer = {
                    OnCalendar = jobCfg.schedule;
                    Persistent = true;
                  };
                  Install = {
                    WantedBy = [ "timers.target" ];
                  };
                };
              }
            ) jobCfg.providers
          )
        )
      ) cfg.jobs;

      buildLaunchdAgents = lib.concatMapAttrs (
        jobName: jobCfg:
        lib.listToAttrs (
          map (
            provider:
            let
              serviceName = jobName;
              script = mkScript jobName jobCfg provider;
              interval = mkLaunchdInterval jobCfg.schedule;
            in
            {
              name = "rclone-sync-${serviceName}";
              value = {
                enable = true;
                config = {
                  ProgramArguments = [ "${script}/bin/rclone-sync-${serviceName}" ];
                  RunAtLoad = false;
                  StandardOutPath = "${hmArgs.config.home.homeDirectory}/Library/Logs/rclone/rclone-sync-${serviceName}.log";
                  StandardErrorPath = "${hmArgs.config.home.homeDirectory}/Library/Logs/rclone/rclone-sync-${serviceName}.log";
                }
                // lib.optionalAttrs (interval != null) {
                  StartInterval = interval;
                };
              };
            }
          ) jobCfg.providers
        )
      ) cfg.jobs;
    in
    {
      options.services.rclone-sync = {
        jobs = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                localPath = lib.mkOption {
                  type = lib.types.str;
                  description = "Absolute path to the local directory to sync.";
                };

                destination = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Remote folder name. If null, uses the job name.";
                };

                providers = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = builtins.attrNames rcloneRemotes;
                  description = "List of rclone remotes to sync to.";
                };

                encrypted = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Use client-side encryption (creates crypt remote).";
                };

                salt = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Use salt for encryption. Only used when encrypted = true.";
                };

                passwordFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "Path to file containing the encryption password. Required when encrypted = true.";
                };

                saltFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "Path to file containing the encryption salt. Required when salt = true.";
                };

                direction = lib.mkOption {
                  type = lib.types.enum [
                    "bisync"
                    "copy"
                    "sync"
                  ];
                  default = "bisync";
                  description = ''
                    Sync direction and strategy:
                    - bisync: bidirectional sync (local ↔ remote)
                    - copy: one-way push (local → remote), never deletes
                    - sync: one-way push (local → remote), deletes remote files not in local
                  '';
                };

                schedule = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = "minutely";
                  description = ''
                    systemd OnCalendar expression for periodic sync. Set to null for manual-only sync.
                    Examples: "minutely", "*:0/5", "hourly", "daily", "Mon..Fri 09:00".
                  '';
                };

                maxDelete = lib.mkOption {
                  type = lib.types.nullOr lib.types.ints.positive;
                  default = 10;
                  description = ''
                    Safety limit on deletions. rclone will abort if more files would be deleted.
                    Only applies to bisync and sync modes. Set to null for unlimited.
                  '';
                };

                exclude = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "List of exclude patterns (passed as --exclude flags to rclone).";
                };
              };
            }
          );
          default = { };
          description = "rclone sync jobs";
        };
      };

      config = lib.mkIf (cfg.jobs != { }) {
        programs.rclone.enable = true;

        # NOTE: home-manager's `rclone-config` launchd agent has two known
        # issues on macOS that cause the config file to become stale:
        #
        #   home-manager#7198 — agent references a nix store path that can be
        #     garbage collected; KeepAlive SuccessfulExit=false prevents reload.
        #   home-manager#8334 — `install -D` overwrites rclone.conf, destroying
        #     dynamic OAuth refresh tokens (Google Drive, OneDrive, etc.).
        #
        # Manual fix when config is stale:
        #   launchctl bootout gui/$(id -u)/org.nix-community.home.rclone-config
        #   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.rclone-config.plist

        assertions = lib.flatten (
          lib.mapAttrsToList (name: job: [
            {
              assertion = !job.encrypted || job.passwordFile != null;
              message = "rclone-sync: job '${name}' has encrypted=true but no passwordFile set";
            }
            {
              assertion = !job.salt || job.saltFile != null;
              message = "rclone-sync: job '${name}' has salt=true but no saltFile set";
            }
          ]) cfg.jobs
        );

        programs.rclone.remotes = lib.concatMapAttrs (
          jobName: jobCfg:
          lib.listToAttrs (
            map (provider: {
              name = config.flake.lib.rclone.mkCryptRemoteName jobName provider;
              value = config.flake.lib.rclone.mkRcloneCryptRemote jobName jobCfg provider;
            }) jobCfg.providers
          )
        ) (lib.filterAttrs (_: jobCfg: jobCfg.encrypted) cfg.jobs);

        systemd.user.services = lib.mkIf isLinux buildServices;
        systemd.user.timers = lib.mkIf isLinux buildTimers;

        launchd.agents = lib.mkIf isDarwin buildLaunchdAgents;
      };
    };
}
