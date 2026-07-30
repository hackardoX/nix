# Beszel Monitoring

This module deploys [Beszel](https://beszel.dev) — a lightweight server monitoring hub with historical data, Docker/Podman stats, and alerts.

## Architecture

- **Hub** (`beszel-hub`): Native NixOS service (not a container) running as the `beszel` user. It provides the web UI and connects to agents via SSH.
- **Agents** (`beszel-agent`): One per service user, running as rootless Podman containers. Each agent reports host metrics + that user's containers to the Hub.

## Network Layout

| Service | Port | Purpose |
|---------|------|---------|
| Beszel Hub | `2000` | Web UI, reverse-proxied by Caddy at `monitoring.homelab4.fun` |
| Agent (alerting) | `2001` | SSH listener for alerting user's containers |
| Agent (homepage) | `2002` | SSH listener for homepage user's containers |
| Agent (job-ops) | `2003` | SSH listener for job-ops user's containers |
| Agent (reactive-resume) | `2004` | SSH listener for reactive-resume user's containers |
| Agent (sure-finance) | `2005` | SSH listener for sure-finance user's containers |

## Manual Setup Required

### 1. OIDC / Authelia

After the Hub is running for the first time, you must manually configure the Authelia OIDC provider in the PocketBase Admin UI:

1. Go to `https://monitoring.homelab4.fun/_/#/settings`
2. Toggle **off** "Hide collection create and edit controls"
3. Edit the `users` collection
4. In the **Options** tab, enable **OAuth2** and add your provider:
   - **Name**: `Authelia`
   - **Client ID**: `beszel`
   - **Client Secret**: (from 1Password / Authelia)
   - **Auth URL**: `https://auth.homelab4.fun/api/oidc/authorization`
   - **Token URL**: `https://auth.homelab4.fun/api/oidc/token`
   - **Userinfo URL**: `https://auth.homelab4.fun/api/oidc/userinfo`
   - **Scopes**: `openid`, `profile`, `email`
5. Toggle the switch back **on**

### 2. Add Systems (Agents)

In the Beszel web UI:

1. Click **Add System**
2. For each agent, set:
   - **Host / IP**: `127.0.0.1`
   - **Port**: the corresponding agent port (e.g., `2004` for reactive-resume)
   - **Name**: e.g., `reactive-resume`
3. The public key is automatically extracted to `/run/beszel/agent-key.pub` and shared with all agents

## 1Password Secrets

The following secrets must exist in your 1Password vault:

- `op://HomeLab/Beszel/Authentication/email` — Initial admin email
- `op://HomeLab/Beszel/Authentication/password` — Initial admin password
- `op://HomeLab/Beszel/Authentication/OIDC client secret` — OIDC client secret for Authelia
- `op://Homelab/Backup/Beszel/password` — Restic encryption key for backups

## Files

- `default.nix` — Hub (NixOS) + Agent (homeManager) module definitions

## Adding Agents to More Services

To monitor another service's containers, import `beszel-agent` into that user's home-manager and set a unique port:

```nix
imports = with config.flake.modules.homeManager; [
  beszel-agent
  # ... other imports
];

services.beszel-agent = {
  enable = true;
  port = config.flake.meta.reverse-proxy.ports.beszel-agent-<service>;
};
```

Then register the new system in the Beszel UI.
