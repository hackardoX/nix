let
  dockerProxyImage = "ghcr.io/tecnativa/docker-socket-proxy:v0.4.2";
in
{
  flake.modules.homeManager.homelab-docker-socket-proxy =
    hmArgs@{
      osConfig,
      lib,
      pkgs,
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

        # Let home-manager itself reconcile *live* sessions gracefully.
        # sd-switch checks `systemctl --user is-system-running` before
        # touching anything, so it no-ops safely if the session isn't
        # reachable instead of throwing.
        systemd.user.startServices = "sd-switch";

        # Declare podman.socket ourselves instead of relying on
        # `systemctl --user enable` from an activation script. Writing
        # these files + the Install symlink is pure filesystem work done
        # by the HM build/activation — it needs no D-Bus/session at all.
        # Because the user has `linger = true`, systemd-logind starts
        # user@901.service at boot regardless of any login, and it will
        # pick these enabled units up on its own.
        systemd.user.sockets.podman = {
          Unit.Description = "Podman API Socket";
          Socket = {
            ListenStream = "%t/podman/podman.sock";
            SocketMode = "0660";
          };
          Install.WantedBy = [ "sockets.target" ];
        };

        systemd.user.services.podman = {
          Unit = {
            Description = "Podman API Service";
            Requires = [ "podman.socket" ];
            After = [ "podman.socket" ];
            StartLimitIntervalSec = 0;
          };
          Service = {
            Delegate = true;
            Type = "exec";
            KillMode = "process";
            ExecStart = "${pkgs.podman}/bin/podman system service";
          };
        };

        services.podman.containers.dockerproxy = {
          image = dockerProxyImage;
          autoStart = true;
          userNS = "keep-id:uid=0,gid=0";
          environment = {
            TZ = osConfig.time.timeZone;
            CONTAINERS = "1";
            POST = "0";
            SOCKET_PATH = "/run/podman/podman.sock";
          };
          volumes = [
            "%t/podman/podman.sock:/run/podman/podman.sock:ro"
          ];
          ports = [ "127.0.0.1:${toString cfg.port}:2375" ];
          extraConfig = {
            Container.NoNewPrivileges = true;
            # Make the container's generated quadlet unit wait for the
            # socket to actually be listening before it tries to bind-mount it.
            Unit = {
              Requires = [ "podman.socket" ];
              After = [ "podman.socket" ];
            };
          };
        };
      };
    };
}
