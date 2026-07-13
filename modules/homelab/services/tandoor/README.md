# Tandoor Recipes Module (Podman)

Self-hosted recipe management application running in Podman containers.

## Usage

```nix
services.tandoor = {
  enable = true;
  port = 8080;                                    # default: 8080
  appDir = "/var/lib/containers/tandoor";           # default
  dataDir = "/var/lib/data/tandoor";               # default
  secretKeyFile = /path/to/secret/key;

  database = {
    name = "tandoor";                             # default
    user = "tandoor";                             # default
    passwordFile = /path/to/db/password;
  };
};
```

This creates the following containers on a `tandoor` bridge network:
- `tandoor` - the app (exposed on `port`)
- `tandoor-db` - PostgreSQL 16

## 1Password Secrets Required

- `op://Homelab/Tandoor/Secret Key/credential` - Django SECRET_KEY
- `op://Homelab/Tandoor/Database/password` - PostgreSQL password
