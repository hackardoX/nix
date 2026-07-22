# Immich Module (Podman)

Self-hosted photo and video management solution running in Podman containers.

## Usage

```nix
services.immich = {
  enable = true;
  port = 2283;                        # default: 2283
  appDir = "/var/lib/containers/immich";     # default
  dataDir = "/var/lib/data/immich";         # default
  dbPasswordFile = /path/to/db/password;
};
```

This creates the following containers on a `immich` bridge network:
- `immich-server` - main app (exposed on `port`)
- `immich-machine-learning` - smart search & face detection
- `immich-redis` - cache (Valkey 9)
- `immich-db` - PostgreSQL with pgvecto.rs

## Storage Layout

```
/var/lib/containers/immich/    (appDir — CoW, compress=zstd)
  photos/        # photo library
  ml-models/     # ML model cache
  ml-dotcache/   # ML .cache
  ml-config/     # ML config

/var/lib/data/immich/          (dataDir — nodatacow)
  postgres/      # database
  redis/         # cache (Valkey)
```
