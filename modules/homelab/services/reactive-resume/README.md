# Reactive Resume Module (Podman)

Self-hosted resume builder running in Podman containers.

## Usage

```nix
services.reactive-resume = {
  enable = true;
  port = 3000;                                          # default: 3000
  appDir = "/var/lib/containers/reactive-resume";      # default
  dataDir = "/var/lib/data/reactive-resume";          # default
  appUrl = "https://resume.example.com";
  authSecretFile = /path/to/auth/secret;

  database = {
    name = "rxresume";          # default
    user = "rxresume";          # default
    passwordFile = /path/to/db/password;
  };
};
```

This creates the following containers on a `reactive-resume` bridge network:
- `reactive-resume` - the app (exposed on `port`)
- `reactive-resume-db` - PostgreSQL 16

Signups are disabled by default (`FLAG_DISABLE_SIGNUPS = true`).
