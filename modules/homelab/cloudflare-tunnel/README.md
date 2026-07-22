# Cloudflare Tunnel Setup

Locally-managed tunnel with declarative ingress rules via NixOS's native
`services.cloudflared.tunnels` module.

## One-Time Setup

Run these commands once from any machine with a browser (the generated files
are portable and can be reused on any machine):

### 1. Install cloudflared

```bash
nix-shell -p cloudflared
```

### 2. Login to Cloudflare

```bash
cloudflared tunnel login
```

This opens a browser for OAuth authentication and creates
`~/.cloudflared/cert.pem` (account certificate, valid 10+ years).

### 3. Create the tunnel

```bash
cloudflared tunnel create homelab4.fun
```

Note the tunnel UUID from the output. This creates the credentials file at
`~/.cloudflared/<uuid>.json`.

### 4. Store credentials in 1Password

- **Vault**: `HomeLab`
- **Item**: `Cloudflare Tunnel/homelab4.fun/credentials`
- **Field**: `credentials` — paste the entire contents of `~/.cloudflared/<uuid>.json`

Optionally, also store `~/.cloudflared/cert.pem` for disaster recovery.

### 5. Route DNS

```bash
cloudflared tunnel route dns homelab4.fun homelab4.fun
cloudflared tunnel route dns homelab4.fun '*.homelab4.fun'
```

This creates CNAME records pointing domains to `<uuid>.cfargotunnel.com`.

### 6. Update tunnel UUID in NixOS config

Replace the UUID in `modules/homelab/cloudflare-tunnel/default.nix` if different
from the current one.

### 7. Deploy

```bash
nix run github:serokell/deploy-rs .#HomeLab
```

## Managing Ingress Rules

Ingress rules are defined declaratively in `default.nix`:

```nix
services.cloudflared.tunnels.<uuid> = {
  originRequest = {
    noTLSVerify = true;           # Skip TLS verification (localhost)
    originServerName = domain;    # SNI expected by Caddy
  };
  ingress = {
    "${domain}" = {
      service = "https://localhost:443";
    };
    "*.${domain}" = {
      service = "https://localhost:443";
    };
    "ssh.${domain}" = "ssh://localhost:22";
  };
  default = "http_status:404";
};
```

To add a new service, add an ingress rule and deploy:

```bash
nix run github:serokell/deploy-rs .#HomeLab
```

## Verifying

```bash
# Check service status
systemctl status cloudflared-tunnel-<uuid>

# Check logs
journalctl -u cloudflared-tunnel-<uuid> -n 50 --no-pager

# Test HTTP access
curl -I https://homelab4.fun
curl -I https://homepage.homelab4.fun

# Test SSH (configure ~/.ssh/config first)
# Host ssh.homelab4.fun
#   User <user>
#   ProxyCommand cloudflared access ssh --hostname %h
ssh ssh.homelab4.fun
```

## Portability

Both `cert.pem` and `credentials.json` are portable files stored in 1Password.
To replicate this setup on another machine, copy both files from 1Password to
`~/.cloudflared/` and deploy the NixOS config. No need to run `tunnel login`
or `tunnel create` again.

## Reference

- [services.cloudflared documentation](https://wiki.nixos.org/wiki/Cloudflared)
- [Cloudflare tunnel configuration file](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/do-more-with-tunnels/local-management/configuration-file/)
- [Supported protocols](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/cloudflared-parameters/run-parameters/)
