# Beszel Monitoring

This module deploys [Beszel](https://beszel.dev) — a lightweight server monitoring hub with historical data, Docker/Podman stats, and alerts.

## Architecture

- **Hub** (`beszel-hub`): Podman container (`ghcr.io/henrygd/beszel/beszel:0.18.7`) running under the `beszel` user's home-manager. Uses **pasta networking** to reach agents on `127.0.0.1` without full host networking.
- **Agents** (`beszel-agent`): One per service user, running as rootless Podman containers. Each agent reports host metrics + that user's containers to the Hub via SSH.

## Network Layout

| Service | Port | Purpose |
|---------|------|---------|
| Beszel Hub | `2000` | Web UI, reverse-proxied by Caddy at `monitoring.homelab4.fun` |
| Agent (alerting) | `2001` | SSH listener for alerting user's containers |
| Agent (homepage) | `2002` | SSH listener for homepage user's containers |
| Agent (job-ops) | `2003` | SSH listener for job-ops user's containers |
| Agent (reactive-resume) | `2004` | SSH listener for reactive-resume user's containers |
| Agent (sure-finance) | `2005` | SSH listener for sure-finance user's containers |

## SSH Keys

Instead of letting the Hub generate an SSH keypair on first boot, you **must provide a pre-generated Ed25519 keypair via 1Password**:

```bash
ssh-keygen -t ed25519 -f beszel_id_ed25519 -N ""
```

Store the resulting files in 1Password:
- `beszel_id_ed25519` → `op://HomeLab/Beszel SSH Key/private key`
- `beszel_id_ed25519.pub` → `op://HomeLab/Beszel SSH Key/public key`

The private key is mounted into the Hub container at `/beszel_data/id_ed25519`.  
The public key is mounted into every agent container at `/run/beszel/agent-key.pub`.

## Manual Setup Required

### 1. First Login (Password Auth)

Password authentication is **enabled by default** so the initial admin can log in:

1. Go to `https://monitoring.homelab4.fun`
2. Sign in with the email and password from 1Password (`op://HomeLab/Beszel/Authentication/*`)
3. Create the admin account if prompted

### 2. OIDC / Authelia

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

**Optional**: After verifying OIDC login works, you can disable password auth by setting `DISABLE_PASSWORD_AUTH = "true"` in the module environment variables and rebuilding.

### 3. Add Systems (Agents)

In the Beszel web UI:

1. Click **Add System**
2. For each agent, set:
   - **Host / IP**: `127.0.0.1`
   - **Port**: the corresponding agent port (e.g., `2004` for reactive-resume)
   - **Name**: e.g., `reactive-resume`
3. The public key is automatically provided to all agents via 1Password

## 1Password Secrets

The following secrets must exist in your 1Password vault:

- `op://HomeLab/Beszel/Authentication/email` — Initial admin email
- `op://HomeLab/Beszel/Authentication/password` — Initial admin password
- `op://HomeLab/Beszel SSH Key/private key` — Ed25519 private key for the Hub
- `op://HomeLab/Beszel SSH Key/public key` — Ed25519 public key for agents
- `op://HomeLab/Beszel/Authentication/OIDC client secret` — OIDC client secret for Authelia
- `op://Homelab/Backup/Beszel/password` — Restic encryption key for backups

## Files

- `default.nix` — Hub (NixOS + homeManager) + Agent (homeManager) module definitions

## Adding Agents to More Services

To monitor another service's containers, import `homelab-beszel-agent` into that user's home-manager and set a unique port:

```nix
imports = with config.flake.modules.homeManager; [
  homelab-beszel-agent
  # ... other imports
];

services.homelab-beszel-agent = {
  enable = true;
  port = config.flake.meta.reverse-proxy.ports.beszel-agent-<service>;
};
```

Then register the new system in the Beszel UI.
