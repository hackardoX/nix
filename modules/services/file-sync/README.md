# File Sync Module

Automated file synchronization using rclone with support for encryption.

## Usage

```nix
services.file-sync.jobs = {
  documents = {
    source = "/home/user/documents";
    providers = [ "koofr" ];        # default: all rclone remotes
    destination = "documents";      # default: job name
    direction = "sync";             # push, pull, sync (default: sync)
    schedule = "daily";             # hourly, daily, weekly (default: daily)
    encrypted = false;              # default: false
    delete = true;                  # default: true
    exclude = [ "*.tmp" ];          # optional
  };
};
```

This creates:
- Sync job: `file-sync-documents-koofr`
- Timer: `file-sync-documents-koofr.timer`

## Encryption

When `encrypted = true`, the module creates a crypt remote (`<provider>-crypt-<jobName>`) wrapping the base remote.

```nix
services.file-sync.jobs = {
  private-docs = {
    source = "/home/user/private-docs";
    providers = [ "koofr" ];
    destination = "private-docs";
    encrypted = true;
    salt = true;  # optional: adds extra security layer
  };
};
```

This creates:
- Crypt remote: `koofr-crypt-private-docs` wrapping `koofr:private-docs`
- Sync job using the encrypted remote

## 1Password Secret Convention

For each **encrypted job**, create a secret in 1Password:

**Vault**: `Homelab`  
**Item name**: `File Sync <job-name>`  
**Field**: `password` (type: password)  
**Reference**: `op://Homelab/File Sync/<job-name>/password`

Example for job `private-docs`:
- Item: `File Sync private-docs`
- Field: `password`
- Reference: `op://Homelab/File Sync/private-docs/password`

If `salt = true`, also create:
- Field: `salt` (type: password)
- Reference: `op://Homelab/File Sync/<job-name>/salt`

The module automatically creates the secret files at `.secrets/file-sync/<job-name>/password` and `.secrets/file-sync/<job-name>/salt`.

## Sync Directions

- **push**: `rclone copy local remote --delete` (local → remote)
- **pull**: `rclone copy remote local --delete` (remote → local)
- **sync**: `rclone bisync local remote --resilient --conflict-resolve newer` (bidirectional)

For bidirectional sync, the module auto-detects if `--resync` is needed on first run.

## Multiple Providers

```nix
services.file-sync.jobs = {
  documents = {
    source = "/home/user/documents";
    providers = [ "koofr" "another" ];
    encrypted = true;
  };
};
```

Creates separate crypt remotes and sync jobs for each provider, all using the same password.
