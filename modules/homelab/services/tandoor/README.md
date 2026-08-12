# Tandoor Recipes Module (Podman)

Self-hosted recipe management application running in Podman containers.

## Usage

Import the module via your flake:

```nix
# NixOS configuration
imports = [ config.flake.modules.nixos.homelab-tandoor ];

# Or as a home-manager module for the tandoor user
imports = [ config.flake.modules.homeManager.homelab-tandoor ];
```

This creates the following containers on a `tandoor` bridge network:

- `tandoor` - the app (exposed on the configured reverse-proxy port)
- `tandoor-db` - PostgreSQL 16

## 1Password Secrets Required

- `op://Homelab/Tandoor/Authentication/secret key` - Django SECRET_KEY
- `op://Homelab/Tandoor/Database/password` - PostgreSQL password
- `op://Homelab/Tandoor/Authentication/OIDC client secret` - OIDC client secret (if OIDC is enabled)
- `op://Homelab/Backup/Tandoor/password` - Backup encryption key

## OIDC Authentication

OIDC is enabled automatically when the `oidc_client_secret` secret is available. The module configures django-allauth:

- `SOCIAL_PROVIDERS` - `allauth.socialaccount.providers.openid_connect`
- `SOCIALACCOUNT_PROVIDERS_FILE` - points to a JSON provider config generated at container start with `provider_id` `authelia`, `client_id` from `config.flake.meta.oidc-clients.tandoor.clientId`, the client secret, and the Authelia discovery URL (`https://${hosts.auth}/.well-known/openid-configuration`)

Ensure your OIDC provider (e.g. Authelia) has a client registered for Tandoor with the redirect URI `https://${hosts.recipes}/accounts/oidc/authelia/login/callback/`.

## Backup

The module configures a daily backup job that captures:

- PostgreSQL data (`/var/lib/data/tandoor/postgres`)
- User media files (`/var/lib/containers/tandoor/mediafiles`)

Backups are encrypted with the `backup_encryption_key` secret and uploaded to the `koofr` provider.
