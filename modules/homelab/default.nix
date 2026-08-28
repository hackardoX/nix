{ config, ... }:
{
  flake.modules.nixos.homelab = {
    imports = with config.flake.modules.nixos; [
      homelab-alerting
      homelab-backup
      homelab-beszel
      homelab-dawarich
      homelab-ingress
      homelab-homepage
      homelab-immich
      homelab-job-ops
      homelab-journal
      # homelab-monitoring
      homelab-reactive-resume
      homelab-security
      homelab-ssh-watchdog
      homelab-sure-finance
      homelab-tandoor
      rclone
    ];

    users.groups.homelab-users = { };
  };
}
