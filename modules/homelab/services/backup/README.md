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
- `backup-gateway` module (append-only sockets to the storage; Backrest reaches the
  repositories through them, so it cannot delete backups, and its prune/forget
  actions are refused. Retention is applied by the weekly `backup-prune-<job>` units)
- `backrest` package from nixpkgs

## Notes

The Backrest service listens on localhost and is proxied through Caddy with auth protection.
