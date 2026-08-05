{ config, lib, ... }:
{
  flake.modules.homeManager.backup =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.postgresql-dump;
      dbOptions = config.flake.lib.types.backup.db;

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
        pkgs.writeShellScript "postgresql-dump-${name}" ''
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
      options.services.postgresql-dump = {
        instances = lib.mkOption {
          type = lib.types.attrsOf dbOptions;
          default = { };
          description = "Database dump instances. Each instance creates a dump service run before its backup job.";
        };
      };

      config = lib.mkIf (cfg.instances != { }) {
        systemd.user.services = lib.mapAttrs' (
          name: instanceCfg:
          lib.nameValuePair "postgresql-dump-${name}" {
            Unit = {
              Description = "Dump postgreSQL database '${name}'";
            };
            Service = {
              Type = "oneshot";
              TimeoutStartSec = 3600;
              ExecStart = toString (mkDumpScript name instanceCfg);
            };
          }
        ) cfg.instances;
      };
    };
}
