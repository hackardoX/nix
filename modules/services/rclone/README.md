# Rclone Module

Enables rclone and installs macFUSE when mounts are configured.

## Usage

Rclone is automatically enabled when either:
- `services.restic.enable = true` (backup module), or
- Any rclone remote has `mounts` configured (file-mount module)

On macOS, `macfuse` is automatically installed via Homebrew when mounts are detected.

## Defining Remotes

Remotes are defined via `programs.rclone.remotes` and consumed by the `backup` and `file-mount` modules.

```nix
programs.rclone.remotes.koofr = {
  config = {
    type = "koofr";
    user = "user@example.com";
    password = "/path/to/password";
  };
};
```

See the `backup` and `file-mount` READMEs for usage examples.

## Google Drive Setup

Google Drive uses OAuth tokens that require periodic refresh. The token is stored in a writable file at `~/.config/rclone/gdrive-token.json` to allow rclone to automatically refresh it.

### One-time setup

After switching to a configuration with Google Drive enabled:

```bash
rclone authorize drive | grep -o '{.*}' > ~/.config/rclone/gdrive-token.json
chmod 600 ~/.config/rclone/gdrive-token.json
```

This creates the token file with the OAuth JSON. Rclone will automatically refresh the access token in this file going forward.
