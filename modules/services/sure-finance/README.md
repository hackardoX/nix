# Sure Finance Module (Podman)

Self-hosted personal finance tracker running in Podman containers.

## Usage

```nix
services.sure-finance = {
  enable = true;
  port = 3000;                                      # default: 3000
  storageDir = "~/containers/sure-finance";          # default
  secretKeyBaseFile = /path/to/secret/key/base;
  openaiTokenFile = /path/to/openai/token;           # optional, enables AI features

  database = {
    name = "sure_production";    # default
    user = "sure_user";          # default
    passwordFile = /path/to/db/password;
  };
};
```

This creates the following containers on a `sure-finance` bridge network:
- `sure-finance-web` - Rails web app (exposed on `port`)
- `sure-finance-worker` - Sidekiq background worker
- `sure-finance-db` - PostgreSQL 16
- `sure-finance-redis` - Redis cache
