# Immich Module (Podman)

Self-hosted photo and video management solution running in Podman containers.

## Usage

```nix
services.immich = {
  enable = true;
  port = 2283;                        # default: 2283
  storageDir = "/var/lib/immich";     # default: /var/lib/immich
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
/var/lib/immich/
  photos/        # photo library
  postgres/      # database
  redis/         # cache
  ml-models/     # ML model cache
  ml-dotcache/   # ML .cache
  ml-config/     # ML config
```
