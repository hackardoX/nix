# File Mount Module (Rclone Mount)

Real-time file synchronization using rclone mounts with support for encryption.

## Usage

```nix
services.file-mount.mounts = {
  documents = {
    providers = [ "koofr" ];           # default: all rclone remotes
    destination = "documents";         # default: mount name
    encrypted = false;                 # default: false
    readOnly = false;                  # default: false
    cacheMode = "full";               # off, minimal, writes, full (default: full)
    cacheMaxSize = "10G";             # default: 10G
  };
};
```

This creates:
- Mount point: `~/documents-koofr`
- Systemd service: `rclone-mount:documents-koofr@koofr.service`
- Auto-mounts on boot (if `autoMount = true`)

## Encryption

When `encrypted = true`, the module creates a crypt remote (`<provider>-crypt-<mountName>`) wrapping the base remote.

```nix
services.file-mount.mounts = {
  private-docs = {
    providers = [ "koofr" ];
    destination = "private-docs";
    encrypted = true;
    salt = true;  # optional: adds extra security layer
  };
};
```

This creates:
- Crypt remote: `koofr-crypt-private-docs` wrapping `koofr:private-docs`
- Mount point: `~/private-docs-koofr`
- Files are encrypted/decrypted transparently

## Cache Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `off` | No caching, direct read/write | Read-only access, minimal disk usage |
| `minimal` | Cache only files opened for read+write | Basic compatibility |
| `writes` | Cache all writes before uploading | Writing files, moderate compatibility |
| `full` | Cache all reads and writes | Full compatibility, offline access |

**Recommendation**: Use `full` for best compatibility and offline access.

## Offline Access

With `cacheMode = "full"`:
- Files are cached locally in `~/.cache/rclone`
- Previously accessed files remain available offline
- Writes are cached and uploaded when connection is restored
- Cache persists across reboots

## 1Password Secret Convention

For each **encrypted mount**, create a secret in 1Password:

**Vault**: `Homelab`  
**Item name**: `File Sync <mount-name>`  
**Field**: `password` (type: password)  
**Reference**: `op://Homelab/File Sync/<mount-name>/password`

Example for mount `private-docs`:
- Item: `File Sync private-docs`
- Field: `password`
- Reference: `op://Homelab/File Sync/private-docs/password`

If `salt = true`, also create:
- Field: `salt` (type: password)
- Reference: `op://Homelab/File Sync/<mount-name>/salt`

The module automatically creates the secret files at `.secrets/file-mount/<mount-name>/password` and `.secrets/file-mount/<mount-name>/salt`.

## Multiple Providers

```nix
services.file-mount.mounts = {
  documents = {
    providers = [ "koofr" "another" ];
    encrypted = true;
  };
};
```

Creates separate crypt remotes and mount points for each provider:
- `~/documents-koofr` (encrypted via `koofr-crypt-documents`)
- `~/documents-another` (encrypted via `another-crypt-documents`)

## Advanced Options

```nix
services.file-mount.mounts = {
  photos = {
    providers = [ "koofr" ];
    cacheMode = "full";
    cacheMaxAge = "24h";        # Keep cache for 24 hours
    cacheMaxSize = "50G";       # Limit cache to 50GB
    dirCacheTime = "10m";       # Cache directory listings for 10 minutes
    pollInterval = "5m";        # Poll for changes every 5 minutes
    readOnly = true;            # Mount as read-only
  };
};
```

## Comparison with Backup Module

| Feature | File Mount (Rclone Mount) | Backup (Restic) |
|---------|---------------------------|-----------------|
| Real-time access | ✅ Yes | ❌ No |
| Offline access | ✅ With cache | ❌ No |
| Versioning | ❌ No | ✅ Yes (snapshots) |
| Deduplication | ❌ No | ✅ Yes |
| Encryption | ✅ Client-side | ✅ Client-side |
| Browsable in Koofr | ✅ Yes (if unencrypted) | ❌ No |
| Use case | Active file access | Disaster recovery |

## Mount vs Sync

**Mount (this module)**:
- Files appear as a virtual filesystem
- Changes are synced in real-time (with caching)
- Best for active file access
- Requires network for uncached files

**Sync (alternative approach)**:
- Files are copied to/from remote on schedule
- Full local copy always available
- Best for offline-first workflows
- Uses `rclone bisync` or `rclone copy`
