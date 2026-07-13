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
