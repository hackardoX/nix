# Cloudflare Tunnel Setup

Manual steps to create the tunnel in the Cloudflare dashboard:

## 1. Create the tunnel

- Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) > Networks > Tunnels
- Click "Create a tunnel", give it a name (e.g. `homelab`)
- Choose connector type "cloudflared"
- Copy the token value shown after creation

## 2. Store the token in 1Password

- Open 1Password, locate the "Homelab" vault
- Create a new "Cloudflare Tunnel" item with a "token" field
- Paste the tunnel token

## 3. Configure public hostnames

In the tunnel's configuration page:

| Subdomain | Domain | Type | URL |
|---|---|---|---|
| `*` | `<yourdomain>` | HTTPS | `localhost:443` |

Under "Additional application settings" > TLS:
- Enable "No TLS Verify" (cloudflared connects to Caddy via localhost)
- Set "Origin Server Name" to `*.yourdomain.com`

## 4. Configure DNS

- Add a CNAME record: `*.yourdomain.com` → `<tunnel-uuid>.cfargotunnel.com`
- Ensure the orange cloud (proxy) is enabled

## 5. Remove router port forwarding

After verifying the tunnel works, remove any port forward rules (443/80) from your router.
