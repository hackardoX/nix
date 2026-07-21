{ config, ... }:
{
  flake.modules.nixos.homelab = {
    imports = with config.flake.modules.nixos; [
      alerting
      docker-socket-proxy
      homepage
      immich
      job-ops
      monitoring
      reactive-resume
      security
      sure-finance
      tandoor
    ];
  };
}
