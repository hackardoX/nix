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
    type = "postgresql";              # currently the only supported type
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

- Creates a `postgresql-dump-<job>.service` (a oneshot dump service, no timer of its own)
- Adds the dump file to the job's `paths`
- Orders the restic service `After` the dump service and `Wants` it, so every backup
  starts with a fresh dump

Because the restic service uses `Wants` (not `Requires`), a failed dump does **not**
prevent the backup from running — restic proceeds with whatever dump file exists.

The dump file is written atomically to `~/backups/postgres/<job>_dump.sql.gz`.

## Append-only gateway (`backup-gateway`)

By default every user with a backup job holds the storage credentials (the
Koofr password), so one compromised service can delete or overwrite every
repository. Importing `flake.modules.nixos.backup-gateway` on the host changes
that:

- For each job, a socket-activated `backup-gateway-<job>` unit serves
  `koofr:backup/<job>` to restic over `/run/backup-gateway/<job>.sock`
  (`rclone serve restic --append-only`: new files only, existing files cannot be
  overwritten, only locks can be deleted).
- The socket is `0660`, group = the job user's group, so a service reaches its
  own repository and no other. The units get the Koofr password through
  `LoadCredential`; service users no longer need it or the `rclone` group.
- Jobs then use `rest:http+unix://.../<job>.sock:/`, and their own `forget` /
  prune is off, because the socket refuses it. The weekly `backup-prune-<job>`
  timer applies the job's `retention` instead (it holds the Koofr password and
  the repository key, in a sandboxed `DynamicUser` unit).
- Jobs must use `providers = [ "koofr" ]`.

This stops a compromised service. It does not stop root on the host.
A failed `backup-prune-<job>` is not notified; check
`systemctl list-units 'backup-prune-*'`.
