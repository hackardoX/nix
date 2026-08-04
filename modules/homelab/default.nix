{ config, ... }:
{
  flake.modules.nixos.homelab = {
    imports = with config.flake.modules.nixos; [
      homelab-alerting
      homelab-beszel
      homelab-ingress
      homelab-homepage
      # homelab-immich
      homelab-job-ops
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
