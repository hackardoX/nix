let
  dockerProxyImage = "ghcr.io/11notes/socket-proxy:2.1.7";
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

          # Container UID/GID 0 must map to *your* host user, not a
          # subordinate uid range: the proxy binary needs to run as
          # (namespace-mapped) root to open podman.sock, exactly like
          # the upstream Tecnativa-based setup. Do NOT change this to
          # uid=1000/gid=1000 — that's only what the proxy internally
          # drops to for its own outward-facing unix socket file
          # (/run/proxy/proxy.sock), which we never touch since we
          # publish over TCP instead.
          userNS = "keep-id:uid=0,gid=0";

          environment = {
            TZ = osConfig.time.timeZone;
            # No CONTAINERS/POST/SOCKET_PATH equivalents here: this image
            # has no per-endpoint allowlist. It always forwards GET/HEAD
            # only, and always rejects everything else with 403, minus a
            # fixed blocklist of sensitive GET paths. Socket source path
            # is also fixed at /run/docker.sock inside the container
            # (see volumes below) rather than configurable via env var.
          };

          volumes = [
            "%t/podman/podman.sock:/run/docker.sock:ro"
          ];

          ports = [ "127.0.0.1:${toString cfg.port}:2375" ];

          extraConfig = {
            Container = {
              NoNewPrivileges = true;
              ReadOnly = true;
              # The entrypoint chowns /run/proxy to 1000:1000 before dropping
              # privileges for its internal outward-facing socket file. With
              # ReadOnly=true the root filesystem has nowhere writable for
              # that directory to exist, so it must be given its own tmpfs.
              Tmpfs = [ "/run/proxy" ];
            };
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
