{ pkgs }:
with pkgs;
[
  # General packages for development and system management
  aldente
  bash-completion
  bat
  coreutils
  eza
  killall
  openssh
  raycast
  sqlite
  vscode
  wget
  zip
  zoxide

  # Cloud-related tools and SDKs
  podman

  # Media-related packages
  spotify

  # Nix development tools
  nixfmt-rfc-style
  nixd

  # Text and terminal utilities
  fd
  jetbrains-mono
  jq
  tree
  unzip

  # Python packages
  python313
  python313Packages.poetry-core
  uv
]
