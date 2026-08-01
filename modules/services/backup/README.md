# Backup Module (Restic)

Automated encrypted backups using restic with rclone remotes.

## Usage

```nix
services.backup.jobs.immich = {
  paths = [ "/var/lib/immich/photos" ];
  schedule = "daily";      # hourly, daily, weekly (default: daily)
  retention = "weekly";    # hourly, daily, weekly, monthly, yearly (default: weekly)
  providers = [ "koofr" ]; # default: all defined rclone remotes
  destination = "immich";  # default: job name
  encryptionKey = config.services.onepassword-secrets.secretPaths.backup_immich_encryption_key;
};
```

This creates:

- Repository: `koofr:immich/backup`
- Timer: `restic-backup-immich-koofr.timer`
- Integrity check: runs after each backup

## 1Password Secret Convention

For each backup job, create a secret in 1Password:

**Vault**: `Homelab`  
**Item name**: `Backup <job-name>`  
**Field**: `password` (type: password)  
**Reference**: `op://Homelab/Backup/<job-name>/password`

Example for job `immich`:

- Item: `Backup immich`
- Field: `password`
- Reference: `op://Homelab/Backup/immich/password`

The module automatically creates the secret file at `.secrets/backup/<job-name>/encryption_key`.

## Retention Policy

Uses time-based retention with `--keep-within`:

- `hourly`: keeps backups from last hour
- `daily`: keeps backups from last day
- `weekly`: keeps backups from last week
- `monthly`: keeps backups from last month
- `yearly`: keeps backups from last year

## Integrity Check

Runs `restic check --read-data` after each backup to verify data integrity.

## Database Dumps

Backup jobs can automatically dump a PostgreSQL database before each backup:

```nix
services.backup.jobs.immich = {
  paths = [ "/var/lib/immich/photos" ];
  db = {
    type = "postgres";                 # currently the only supported type
    user = "postgres";                 # database superuser (default: postgres)
    passwordFile = null;               # optional path to a password file
    container = {                      # optional, null = local pg_dumpall
      type = "podman";                 # or "docker"
      name = "immich-db";
    };
  };
};
```

This automatically:
- Creates a `postgres-dump-<job>.service` + `.timer` (runs 30 min before the backup)
- Adds the dump file to the job's `paths`
- Adds `After=` ordering from the restic service to the dump service

The dump file is written atomically to `~/backups/postgres/<job>_dump.sql.gz`.

Override the dump timer schedule via `services.postgres-dump.instances`:

```nix
services.postgres-dump.instances.immich = {
  calendar = "*-*-* 03:00:00";  # overrides the auto-computed schedule
};
```

For standalone use (without restic), configure instances directly:

```nix
services.postgres-dump.instances.myblog = {
  type = "postgres";
  container = { type = "podman"; name = "blog-db"; };
  # no backup job needed, just a dump on its own timer
};
