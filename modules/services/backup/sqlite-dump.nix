{ config, lib, ... }:
{
  flake.modules.homeManager.backup =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.sqlite-dump;
      dbOptions = config.flake.lib.types.backup.db;

      mkDumpScript =
        name: instanceCfg:
        pkgs.writeShellScript "sqlite-dump-${name}" ''
          set -euo pipefail

          OUT_DIR="${instanceCfg.backupDir}"
          FINAL_FILE="${instanceCfg.backupDir}/${instanceCfg.filename}"
          TMP_FILE="${instanceCfg.backupDir}/.${instanceCfg.filename}.tmp"

          cleanup() { rm -f "$TMP_FILE"; }
          trap cleanup EXIT

          mkdir -p "$OUT_DIR"

          ${pkgs.sqlite}/bin/sqlite3 "${instanceCfg.dbPath}" ".backup '${instanceCfg.backupDir}/.${name}_dump.db'"

          ${pkgs.gzip}/bin/gzip -${toString instanceCfg.compressionLevel} "${instanceCfg.backupDir}/.${name}_dump.db" > "$TMP_FILE"

          rm -f "${instanceCfg.backupDir}/.${name}_dump.db"

          mv "$TMP_FILE" "$FINAL_FILE"
        '';
    in
    {
      options.services.sqlite-dump = {
        instances = lib.mkOption {
          type = lib.types.attrsOf dbOptions;
          default = { };
          description = "SQLite database dump instances. Each instance creates a dump service run before its backup job.";
        };
      };

      config = lib.mkIf (cfg.instances != { }) {
        systemd.user.services = lib.mapAttrs' (
          name: instanceCfg:
          lib.nameValuePair "sqlite-dump-${name}" {
            Unit = {
              Description = "Dump SQLite database '${name}'";
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
