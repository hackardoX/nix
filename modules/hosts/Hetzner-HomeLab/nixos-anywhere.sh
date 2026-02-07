#!/usr/bin/env bash

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directories
install -d -m755 "$temp/etc"
install -d -m755 "$temp/etc/ssh"
install -d -m755 "$temp/etc/.secrets"

# Decrypt your secrets from the password store and copy it to the temporary directory
op read --no-newline "op://Development/1Password Service Account/credential" >"$temp/etc/opnix-token"
op read "op://Development/Hetzner HomeLab/private key?ssh-format=openssh" >"$temp/etc/ssh/ssh_host_ed25519_key"
op read "op://Development/Hetzner HomeLab/public key" >"$temp/etc/ssh/ssh_host_ed25519_key.pub"
op read --no-newline "op://Development/Hetzner HomeLab/hashed user password" >"$temp/etc/.secrets/.hetzner_password"

# Set the correct permissions
chmod 600 "$temp/etc/opnix-token"
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"
chmod 644 "$temp/etc/ssh/ssh_host_ed25519_key.pub"
chmod 600 "$temp/etc/.secrets/.hetzner_password"

# Install NixOS to the host system with our secrets
nix run github:nix-community/nixos-anywhere -- --flake .#Hetzner-HomeLab --extra-files "$temp" --disk-encryption-keys /tmp/disk.key <(op read --no-newline 'op://Development/Hetzner HomeLab/disk encryption key') --build-on remote root@hetzner-homelab
