<h3 align="center">
 <img alt="Avatar" src="https://avatars.githubusercontent.com/u/10788630?v=4" width="100"/>
 <br/>
 <br/>
 <span>
 <img alt="NixOS" src="https://raw.githubusercontent.com/devicons/devicon/ca28c779441053191ff11710fe24a9e6c23690d6/icons/nixos/nixos-original.svg" height="20" align="center"/> Nix config for <a href="https://github.com/hackardoX">hackardoX</a>
 </span>
</h3>

<p align="center">
 <a href="https://github.com/hackardoX/nix/commits"><img alt="Last commit" src="https://img.shields.io/github/last-commit/hackardoX/nix?colorA=363a4f&colorB=f5a97f&style=for-the-badge"></a>
  <a href="https://wiki.nixos.org/wiki/Flakes" target="_blank">
 <img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge">
</a>
</p>

Welcome to my personal Nix configuration repository. This repository contains my
nix-darwin configuration for macOS, built using
[flake-parts](https://flake.parts/) and following the
[dendritic pattern](https://github.com/mightyiam/dendritic).

## Table of Contents

1. [Getting Started](#getting-started)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Resources](#resources)

## Getting Started

Before diving in, ensure that you have Nix installed on your system. If not, you
can download and install it from the official
[Nix website](https://nixos.org/download.html) or from the
[Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer).

### Clone and setup

```bash
# Install git if needed:
nix-shell -p git

git clone https://github.com/hackardoX/nix.git
cd nix

# First-time setup on macOS:
nix run github:lnl7/nix-darwin#darwin-rebuild -- switch --flake .

# macOS (darwin hosts):
nh darwin switch          # Andrea-MacBook-Air, Proton-MacBook-Pro

# NixOS (HomeLab), on the machine itself:
sudo nh os switch         # HomeLab (Apple Silicon)
```

## Remote Deployment

Initial provisioning for NixOS nodes (e.g., HomeLab on Apple Silicon, Hetzner VPS):

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#HomeLab --build-on remote <user>@<ip_address>
```

Subsequent updates via deploy-rs:

```bash
nix run github:serokell/deploy-rs .#<host>   # e.g., .#HomeLab
```

## Features

Here's an overview of what my Nix configuration offers:

- **Partitioned Inputs**: Separate flakes for `homelab` and `laptops` isolate private/host-specific dependencies (e.g., `asahi-firmware`) from the root lockfile.
- **Flake-parts Architecture**: Modular flake structure using [flake-parts](https://flake.parts/) for better composability and organization.

- **Dendritic Pattern**: Configuration follows the
  [dendritic pattern](https://github.com/mightyiam/dendritic) for a clean,
  modular structure.

- **External Dependency Integrations**:
  - [Nixvim](https://github.com/nix-community/nixvim) for Neovim configuration.
  - [Catppuccin](https://github.com/catppuccin/nix) for consistent, high-quality system-wide theming.
  - [Git-hooks](https://github.com/cachix/pre-commit-hooks.nix) for automated commit validation (Commitizen, Sign-offs).
  - [Treefmt-nix](https://github.com/numtide/treefmt-nix) for a unified formatting interface.

- **macOS Support**: Seamlessly configure and manage Nix on macOS using
  [nix-darwin](https://github.com/LnL7/nix-darwin).

- **Home Manager**: Manage your dotfiles, home environment, and user-specific
  configurations with
  [Home Manager](https://github.com/nix-community/home-manager).

- **DevShell Support**: The flake provides a development shell for convenient
  development and maintenance of your Nix environment.

- **Secret Management**: Secure secret handling with [sops-nix](https://github.com/Mic92/sops-nix).
- **CI with Cachix**: Continuous integration that pushes built artifacts to [Cachix](https://github.com/cachix/cachix) for efficient builds.

- **Remote Deployment**: Easily deploy Nix configuration with [deploy-rs](https://github.com/serokell/deploy-rs)

## Architecture

This configuration uses **flake-parts** with the **dendritic pattern** for a
modular and composable structure.

### Dendritic Pattern

The dendritic pattern organizes Nix configurations into small, focused modules
that compose together like dendrites in a neural network. Each module defines a
specific piece of functionality and declares its dependencies explicitly.

Key benefits:

- **Modularity**: Each feature is isolated in its own module
- **Composability**: Modules combine freely and can be reused across
  configurations
- **Clarity**: Module relationships and dependencies are explicit and declarative

Learn more at the
[dendritic pattern documentation](https://github.com/mightyiam/dendritic).

### Directory Structure

```
.
├── flake.nix                        # Main entry point
├── partitions/                      # Isolated input sets
│   ├── homelab/flake.nix            # Apple Silicon NixOS deps
│   └── laptops/flake.nix            # macOS hosts deps
└── modules/                         # Shared configuration
    ├── hosts/                       # Host-specific configs
    │   ├── HomeLab/                 # NixOS (aarch64-linux)
    │   ├── Andrea-MacBook-Air/      # Darwin (aarch64-darwin)
    │   └── ...
    └── ...                          # Feature modules
```

All modules are discovered recursively using
[flake-parts' import-tree](https://github.com/hercules-ci/flake-parts-files).
The `modules/hosts/` directory contains host-specific configurations that select
which modules to enable for each machine.

### Module Organization

Configuration is organized into focused modules by functionality (e.g., shell,
git, editor, fonts). Each host configuration in `modules/hosts/` selects which
modules to enable and provides host-specific settings like username and system
version.

## Resources

Configurations that inspired this setup:

- [mightyiam/infra](https://github.com/mightyiam/infra) - **Main inspiration for
  the dendritic pattern and flake-parts structure**
- [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config) -
  Initial starting point
- [khaneliman/khanelinix](https://github.com/khaneliman/khanelinix) -
  Configuration inspiration

Documentation:

- [dendritic pattern](https://github.com/Doc-Steve/dendritic-design-with-flake-parts)
