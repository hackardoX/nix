{ lib, ... }:
{
  flake.lib.types.backup.db = lib.types.submodule (
    { name, config, ... }: {
      options = {
        type = lib.mkOption {
          type = lib.types.enum [
            "postgresql"
            "sqlite"
          ];
          default = "postgresql";
          description = "Database type";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "postgres";
          description = "Database administrative user used to create dumps";
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
          description = "Container running the database. Null = database accessible locally.";
        };

        dbPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Path to the SQLite database file (required for sqlite type)";
        };

        backupDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/backups/${name}/db";
          description = "Directory to store dumps";
        };

        filename = lib.mkOption {
          type = lib.types.str;
          default = if config.type == "sqlite" then "${name}_dump.db.gz" else "${name}_dump.sql.gz";
          description = "Dump filename (in backupDir)";
        };

        compressionLevel = lib.mkOption {
          type = lib.types.ints.between 1 9;
          default = 6;
          description = "Gzip compression level (1-9)";
        };

        outputPath = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${config.backupDir}/${config.filename}";
          description = "Computed full path of the dump file";
        };
      };
    }
  );
}
