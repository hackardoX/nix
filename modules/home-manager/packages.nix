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
  warp-terminal
  wget
  zip
  zoxide

  # Cloud-related tools and SDKs
  docker
  docker-compose

  # Media-related packages
  spotify

  # Node.js development tools
  nodePackages.npm
  nodePackages.prettier
  nodejs

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
  python312
  python312Packages.poetry-core
]
