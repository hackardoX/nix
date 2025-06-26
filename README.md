<h3 align="center">
 <img src="https://avatars.githubusercontent.com/u/10788630?v=4" width="100" alt="Logo"/><br/>
 <span style="display:flex;justify-content:center;margin-top:8px;gap:4px;">
 <img src="https://upload.wikimedia.org/wikipedia/commons/c/c4/NixOS_logo.svg" height="25" /><p style="all:unset;">config for <a href="https://github.com/andrea11">Andrea11</a></p>
 </span>
</h3>

<p align="center">
 <a href="https://github.com/andrea11/nix/commits"><img src="https://img.shields.io/github/last-commit/andrea11/nix?colorA=363a4f&colorB=f5a97f&style=for-the-badge"></a>
  <a href="https://wiki.nixos.org/wiki/Flakes" target="_blank">
 <img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge">
</a>
<a href="https://github.com/snowfallorg/lib" target="_blank">
 <img alt="Built With Snowfall" src="https://img.shields.io/static/v1?logoColor=d8dee9&label=Built%20With&labelColor=5e81ac&message=Snowfall&color=d8dee9&style=for-the-badge">
</a>
</p>

Welcome to my personal Nix configuration repository. This repository
contains my NixOS and Nixpkgs configurations for MacOS.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Features](#features)
3. [Customization](#customization)
   1. [Abstraction](#abstraction)
4. [Resources](#resources)

## Getting Started

Before diving in, ensure that you have Nix installed on your system. If not, you
can download and install it from the official
[Nix website](https://nixos.org/download.html) or from the
[Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer).
If running on macOS, you need to have Nix-Darwin installed, as well. You can
follow the installation instruction on
[GitHub](https://github.com/LnL7/nix-darwin?tab=readme-ov-file#flakes).

### Clone this repository to your local machine

```bash
# New machine without git
nix-shell -p git

# Clone
git clone https://github.com/andrea11/nix.git
cd nix

# First run without nix-darwin:
nix run github:lnl7/nix-darwin#darwin-rebuild -- switch --flake github:andrea11/nix
# or
nix build github:andrea11/nix#darwinConfigurations.Andrea-MacBook-Air.system
sudo ./result/sw/bin/darwin-rebuild switch --flake .#Andrea-MacBook-Air

# Subsequent runs:
darwin-rebuild switch --flake .

# Direnv
flake switch
```

## Features

Here's an overview of what my Nix configuration offers:

- **External Dependency Integrations**:

  - [Nixvim](https://github.com/nix-community/nixvim) neovim configuration.
  - Access the Nix User Repository (NUR) for additional packages and
    enhancements.
  - Incorporate Nixpkgs-Wayland to provide an up-to-date Wayland package
    repository.

- **macOS Support**: Seamlessly configure and manage Nix on macOS using the
  power of [Nix-darwin](https://github.com/LnL7/nix-darwin), also leveraging
  homebrew for GUI applications.

- **Home Manager**: Manage your dotfiles, home environment, and user-specific
  configurations with
  [Home Manager](https://github.com/nix-community/home-manager).

- **DevShell Support**: The flake provides a development shell (`devShell`) to
  support maintaining this flake. You can use the devShell for convenient
  development and maintenance of your Nix environment.

- **CI with Cachix**: The configuration includes continuous integration (CI)
  that pushes built artifacts to [Cachix](https://github.com/cachix/cachix).
  This ensures efficient builds and reduces the need to build dependencies on
  your local machine.

- **Utilize opnix or sops-nix**: Secret management with
  [opnix](https://github.com/brizzbuzz/opnix) or [sops-nix](https://github.com/Mic92/sops-nix)
  for secure and encrypted handling of sensitive information.

## Customization

My Nix configuration, based on the
[SnowfallOrg lib](https://github.com/snowfallorg/lib) structure, provides a
flexible and organized approach to managing your Nix environment. Here's how it
works:

- **Custom Library**: An optional custom library in the `lib/` directory
  contains a Nix function called with `inputs`, `snowfall-inputs`, and `lib`.
  The function should return an attribute set to merge with `lib`.

- **Modular Directory Structure**: You can create any (nestable) directory
  structure within `lib/`, `packages/`, `modules/`, `overlays/`, `systems/`, and
  `homes/`. Each directory should contain a Nix function that returns an
  attribute set to merge with the corresponding section.

- **Package Overlays**: The `packages/` directory includes an optional set of
  packages to export. Each package is instantiated with `callPackage`, and the
  files should contain functions that take an attribute set of packages and the
  required `lib` to return a derivation.

- **Modules for Configuration**: In the `modules/` directory, you can define
  NixOS modules for various platforms, such as `darwin`, and `home`.
  This modular approach simplifies system configuration management.

- **System Configurations**: The `systems/` directory organizes system
  configurations based on architecture and format. You can create configurations
  for different architectures and formats, such as `x86_64-linux`,
  `aarch64-darwin`, and more.

- **Home Configurations**: Similar to system configurations, the `homes/`
  directory organizes home configurations based on architecture and format. This
  is especially useful if you want to manage home environments with Nix.

This structured approach to Nix configuration makes it easier to manage and
customize your Nix environment while maintaining flexibility and modularity.

### Abstraction

Each module comes with its own set of options. To streamline the composition of these modules, we utilize what we refer to as `suites`, which allow for the simultaneous activation of a group of modules. These `suites` function similarly to facades in programming languages: depending on a specific role within a suite (such as development), certain tools will be automatically installed.

To prevent redundancy, the options for suites are defined in the `/modules/shared/suites-options/` directory and are imported into both the `darwin` and `home` suite modules.

Suites are employed in both `homes` and `systems`: instead of manually enabling individual modules, only suites are managed. The collection of suites enabled for a particular home and system is defined as a `profile`, and these profiles are located in `/shared/profiles/<system-name>`.

# Resources

Other configurations from where I learned and copied:

- [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config) _Initial starting point_
- [khaneliman/khanelinix](https://github.com/khaneliman/khanelinix) **Main
  inspiration**
