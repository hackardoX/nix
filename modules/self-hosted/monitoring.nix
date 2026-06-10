{ config, ... }:
{
  flake.modules.homeManager."${config.flake.meta.monitoring.user}@homelab" = hmArgs: {
    services.monitoring = {
      enable = true;
    };
  };
}
