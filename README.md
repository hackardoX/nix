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

### Clone this repository to your local machine

```bash
# New machine without git
nix-shell -p git

# Clone
git clone https://github.com/hackardoX/nix.git
cd nix

# First run without nix-darwin:
nix run github:lnl7/nix-darwin#darwin-rebuild -- switch --flake github:hackardoX/nix
# or
nix build github:hackardoX/nix#darwinConfigurations.Andrea-MacBook-Air.system
sudo ./result/sw/bin/darwin-rebuild switch --flake .#Andrea-MacBook-Air

# Subsequent runs:
darwin-rebuild switch --flake .

# Or with nh (recommended):
nh darwin switch
```

## Remote Deployment

For NixOS nodes (like Hetzner VPS), I use [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) for the initial unattended installation and [deploy-rs](https://github.com/serokell/deploy-rs) for subsequent updates.

### Initial Provisioning

To install NixOS on a fresh machine (ensure the machine is in a Rescue/Live environment with SSH access):

```bash
nix run github:nix-community/nixos-anywhere -- --flake .#<nix_host> --build-on remote <user>@<ip_address>
```

### Updates

Once provisioned, deploy changes safely using deploy-rs:

```bash
nix run github:serokell/deploy-rs .#<nix_host>
```

## Features

Here's an overview of what my Nix configuration offers:

- **Flake-parts Architecture**: Modular flake structure using
  [flake-parts](https://flake.parts/) for better composability and organization.

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

- **CI with Cachix**: Continuous integration that pushes built artifacts to
  [Cachix](https://github.com/cachix/cachix) for efficient builds.

- **Secret Management**: Secure handling of sensitive information with
  [opnix](https://github.com/brizzbuzz/opnix).

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
├── flake.nix              # Main flake entry point
└── modules/
    ├── darwin/            # nix-darwin modules
    ├── homeManager/       # Home Manager modules
    ├── nixvim/            # Nixvim configuration
    ├── hosts/             # Host-specific configurations
    └── ...                # Additional feature modules
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
