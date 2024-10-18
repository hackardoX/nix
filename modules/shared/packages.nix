{ pkgs }:

with pkgs;
[
  # General packages for development and system management
  _1password
  _1password-gui
  bash-completion
  bat
  coreutils
  eza
  killall
  openssh
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
