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
