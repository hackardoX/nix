let
  dockerProxyImage = "ghcr.io/tecnativa/docker-socket-proxy:latest";
in
{
  flake.modules.homeManager.homelab-docker-socket-proxy =
    hmArgs@{
      osConfig,
      lib,
      ...
    }:
    let
      cfg = hmArgs.config.services.homelab-docker-socket-proxy;
    in
    {
      options.services.homelab-docker-socket-proxy = {
        enable = lib.mkEnableOption "a read-only docker-socket-proxy for this user's own podman";
        port = lib.mkOption {
          type = lib.types.port;
          description = "Loopback port to publish the proxy on. Must be unique per user on this host.";
        };
      };

      config = lib.mkIf cfg.enable {
        services.podman.enable = true;

        services.podman.containers.dockerproxy = {
          image = dockerProxyImage;
          autoStart = true;
          userNS = "keep-id";
          environment = {
            TZ = osConfig.time.timeZone;
            CONTAINERS = "1";
            POST = "0";
            SOCKET_PATH = "/run/podman/podman.sock";
          };
          volumes = [
            "%t/systemd/user/podman.socket:/run/podman/podman.sock:ro"
          ];
          ports = [ "127.0.0.1:${toString cfg.port}:2375" ];
          extraConfig.Container.NoNewPrivileges = true;
        };
      };
    };
}
