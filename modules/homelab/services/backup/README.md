# Backrest Dashboard (Restic Web UI)

Web UI for browsing Restic backup repositories managed by the backup module.

## Configuration

The dashboard is automatically configured when the homelab module is imported. It provides a web interface at the configured backup hostname (e.g., `backup.homelab4.fun`).

## Features

- Browse all configured backup repositories (beszel, immich, job-ops, sure-finance, dawarich, reactive-resume, tandoor)
- View backup history and metadata
- Auth: disabled by default (adjust in config if needed)

## Dependencies

- `backup` module (for backup jobs)
- `rclone` module (remote storage access)
- `backrest` package from nixpkgs

## Notes

The Backrest service listens on localhost and is proxied through Caddy with auth protection.
