# sops-nix Secrets Management

This directory contains encrypted secrets managed by sops-nix using age encryption.

## Architecture

- **Dedicated age keys** per host (not derived from SSH keys)
- **Encrypted secrets** in YAML format
- **Automatic decryption** at boot via sops-nix

## Age Keys

Each host has a dedicated age key stored at `/var/lib/sops/age-key.txt`.

### Key Locations

| Host | Public Key | Private Key Location |
|------|-----------|---------------------|
| HomeLab | `age1rua8fvjun2eq6cgrece2g5995ajezn3l2d0q5nptc855vffkhyrs6v8u6z` | `/var/lib/sops/age-key.txt` |
| Hetzner-HomeLab | `age1e8rcwtgz6d0meurr73n4ssxvt7ej496ezxqdsafc2vcj93spwvgqmrgs80` | `/var/lib/sops/age-key.txt` |
| Andrea-MacBook-Air | `age1nd2nc46ustuylq8zt90a2lv7t9r0epqsamsfq3saffnzfnh9au7q2cvkf9` | `/var/lib/sops/age-key.txt` |
| Proton-MacBook-Pro | `age1nycq6ranp0s4w5nqpd0ge80de85sq7n83fnzw740mpt89kpa8cfq3zauzf` | `/var/lib/sops/age-key.txt` |

## Initial Setup

### 1. Generate Age Keys

On each host:

```bash
sudo mkdir -p /var/lib/sops
sudo age-keygen -o /var/lib/sops/age-key.txt
sudo chmod 600 /var/lib/sops/age-key.txt
```

### 2. Extract Public Keys

```bash
cat /var/lib/sops/age-key.txt | grep "Public key" | awk '{print $3}'
```

### 3. Update `.sops.yaml`

Add the public key to the appropriate host entry in `.sops.yaml`:

```yaml
keys:
  - &HomeLab age1...  # Replace with actual public key
```

### 4. Encrypt Secrets

```bash
# Encrypt homelab services secrets
sops --encrypt --in-place secrets/homelab/services.yaml

# Encrypt host-specific secrets
sops --encrypt --in-place secrets/hosts/HomeLab/secrets.yaml
```

## Secret Structure

```
secrets/
├── homelab/
│   └── services.yaml          # Shared secrets for both NixOS hosts
├── hosts/
│   ├── HomeLab/
│   │   └── secrets.yaml       # HomeLab-specific secrets
│   ├── Hetzner-HomeLab/
│   │   └── secrets.yaml       # Hetzner-specific secrets
│   ├── Andrea-MacBook-Air/
│   │   └── secrets.yaml       # Andrea Mac secrets
│   └── Proton-MacBook-Pro/
│       └── secrets.yaml       # Proton Mac secrets
└── users/
    ├── hal.yaml               # Hal user password hash
    └── hetzner.yaml           # Hetzner user password hash
```

## Accessing Secrets in NixOS Modules

```nix
# Declare a secret
sops.secrets."my-service/api-key" = {
  owner = "my-service";
  group = "my-service";
  mode = "0400";
};

# Use the secret
systemd.services.my-service = {
  environment.API_KEY_FILE = config.sops.secrets."my-service/api-key".path;
};
```

## Re-encrypting Secrets

If you need to add/remove a host key:

```bash
# Update all secrets with new key configuration
sops updatekeys secrets/homelab/services.yaml
sops updatekeys secrets/hosts/HomeLab/secrets.yaml
```

## Troubleshooting

### Secrets not decrypting

1. Check age key exists: `ls -la /var/lib/sops/age-key.txt`
2. Verify permissions: `stat -c %a /var/lib/sops/age-key.txt` (should be 600)
3. Check sops logs: `journalctl -u sops-nix.service`

### After host reinstall

1. Restore age key from 1Password (see above)
2. Rebuild system: `sudo nixos-rebuild switch`
3. Verify secrets: `ls -la /run/secrets/`
