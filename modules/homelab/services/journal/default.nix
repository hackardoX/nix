{
  config,
  ...
}:
let
  hosts = config.flake.meta.reverse-proxy.hosts;
  port = config.flake.meta.reverse-proxy.ports.grafito;
in
{
  flake.meta.homepage.services.journal = {
    category = "Monitoring";
    name = "Journal";
    description = "Systemd Journal Viewer";
    icon = "linux";
    href = "https://${hosts.logs}";
    siteMonitor = "http://localhost:${toString port}";
    pingPort = port;
  };

  flake.modules.nixos.homelab-journal =
    {
      pkgs,
      ...
    }:
    let
      grafito = pkgs.fetchurl {
        url = "https://github.com/ralsina/grafito/releases/download/v0.17.0/grafito-static-linux-arm64";
        sha256 = "sha256-38GmqDCc6CBSVJ0adQ1qatzqB2vuefYz3mShuVIMjmk=";
        executable = true;
      };
    in
    {
      systemd.services.grafito = {
        description = "Grafito systemd journal web viewer";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-journald.service" ];
        serviceConfig = {
          Type = "simple";
          DynamicUser = true;
          # Grant access to the full system + per-user rootless container journals
          Group = "systemd-journal";
          ExecStart = "${grafito} -b 127.0.0.1 -p ${toString port}";
          Restart = "on-failure";
          RestartSec = "5s";
          NoNewPrivileges = true;
          CapabilityBoundingSet = "";
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectClock = true;
          ProtectHostname = true;
          LockPersonality = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RestrictNamespaces = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" ];
          IPAddressAllow = "localhost";
          IPAddressDeny = "any";
          UMask = "0077";
        };
      };

      services.caddy.virtualHosts."${hosts.logs}" = {
        extraConfig = ''
          import auth_protected
          import reverse_proxy_common
          reverse_proxy localhost:${toString port}
        '';
      };
    };
}
