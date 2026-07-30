{
  lib,
  config,
  pkgs,
  ...
}:
{
  flake.modules.homeManager.postgresDump =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      hmConfig = config;
      cfg = config.services.postgres-dump;

      mkDumpScript =
        name: instanceCfg:
        let
          runner =
            if instanceCfg.container != null then
              if instanceCfg.container.type == "podman" then
                "${pkgs.podman}/bin/podman exec ${lib.escapeShellArg instanceCfg.container.name}"
              else
                "${pkgs.docker}/bin/docker exec ${lib.escapeShellArg instanceCfg.container.name}"
            else
              "";
        in
        pkgs.writeShellScript "postgres-dump-${name}" ''
          set -euo pipefail

          OUT_DIR="${instanceCfg.backupDir}"
          FINAL_FILE="${instanceCfg.backupDir}/${instanceCfg.filename}"
          TMP_FILE="${instanceCfg.backupDir}/.${instanceCfg.filename}.tmp"

          cleanup() { rm -f "$TMP_FILE"; }
          trap cleanup EXIT

          mkdir -p "$OUT_DIR"

          ${lib.optionalString (instanceCfg.passwordFile != null) ''
            export PGPASSWORD="$(cat "${instanceCfg.passwordFile}")"
          ''}

          ${runner} pg_dumpall -U "${instanceCfg.user}" --clean \
            | ${pkgs.gzip}/bin/gzip -${toString instanceCfg.compressionLevel} > "$TMP_FILE"

          mv "$TMP_FILE" "$FINAL_FILE"
        '';
    in
    {
      options.services.postgres-dump = {
        instances = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, config, ... }: {
                options = {
                  type = lib.mkOption {
                    type = lib.types.enum [ "postgres" ];
                    default = "postgres";
                    description = "Database type";
                  };

                  user = lib.mkOption {
                    type = lib.types.str;
                    default = "postgres";
                    description = "Database superuser for pg_dumpall";
                  };

                  passwordFile = lib.mkOption {
                    type = lib.types.nullOr lib.types.path;
                    default = null;
                    description = "Path to file containing the database password";
                  };

                  container = lib.mkOption {
                    type = lib.types.nullOr (
                      lib.types.submodule {
                        options = {
                          type = lib.mkOption {
                            type = lib.types.enum [
                              "podman"
                              "docker"
                            ];
                            description = "Container runtime";
                          };
                          name = lib.mkOption {
                            type = lib.types.str;
                            description = "Container name";
                          };
                        };
                      }
                    );
                    default = null;
                    description = "Container running the database. Null = local postgres accessible via pg_dumpall.";
                  };

                  backupDir = lib.mkOption {
                    type = lib.types.str;
                    default = "${hmConfig.home.homeDirectory}/backups/postgres";
                    description = "Directory to store dumps";
                  };

                  filename = lib.mkOption {
                    type = lib.types.str;
                    default = "${name}_dump.sql.gz";
                    description = "Dump filename (in backupDir)";
                  };

                  compressionLevel = lib.mkOption {
                    type = lib.types.ints.between 1 9;
                    default = 6;
                    description = "Gzip compression level (1-9)";
                  };

                  calendar = lib.mkOption {
                    type = lib.types.str;
                    default = "*-*-* 23:30:00";
                    description = "systemd OnCalendar schedule for the dump timer";
                  };

                  outputPath = lib.mkOption {
                    type = lib.types.str;
                    readOnly = true;
                    default = "${config.backupDir}/${config.filename}";
                    description = "Computed full path of the dump file";
                  };
                };
              }
            )
          );
          default = { };
          description = "Database dump instances. Each instance creates a systemd service + timer.";
        };
      };

      config = lib.mkIf (cfg.instances != { }) {
        systemd.user.services = lib.mapAttrs' (
          name: instanceCfg:
          lib.nameValuePair "postgres-dump-${name}" {
            Unit = {
              Description = "Dump ${instanceCfg.type} database '${name}'";
            };
            Service = {
              Type = "oneshot";
              ExecStart = toString (mkDumpScript name instanceCfg);
            };
          }
        ) cfg.instances;

        systemd.user.timers = lib.mapAttrs' (
          name: instanceCfg:
          lib.nameValuePair "postgres-dump-${name}" {
            Unit.Description = "Timer for ${instanceCfg.type} dump '${name}'";
            Timer = {
              OnCalendar = instanceCfg.calendar;
              Persistent = true;
            };
            Install.WantedBy = [ "timers.target" ];
          }
        ) cfg.instances;
      };
    };
}
