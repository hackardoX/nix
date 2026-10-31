{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  hmUsers = host.home-manager.users;
  inherit (config.flake.lib.checks) mkCheck mkSystemdCheck;
  homepageServices = config.flake.meta.homepage.services;
  reverseProxy = config.flake.meta.reverse-proxy;

  # --- homepage-proxy-ports ----------------------------------------------

  proxyOf = h: h.services.homelab-docker-socket-proxy or { enable = false; };
  enabledProxyPorts = lib.concatLists (
    lib.mapAttrsToList (
      _: h:
      let
        proxy = proxyOf h;
      in
      lib.optional (proxy.enable or false) proxy.port
    ) hmUsers
  );

  proxyFailures = lib.concatLists (
    lib.mapAttrsToList (
      name: svc:
      lib.optional
        (svc.dockerSocketProxyPort != null && !lib.elem svc.dockerSocketProxyPort enabledProxyPorts)
        "homepage.services.${name}: dockerSocketProxyPort ${toString svc.dockerSocketProxyPort} matches no enabled services.homelab-docker-socket-proxy on HomeLab-CI"
    ) homepageServices
  );

  # --- homepage-lib ------------------------------------------------------

  libTests = {
    testBeszelWidget = {
      expr = config.flake.lib.beszel.mkWidget { systemId = "Test"; };
      expected = {
        type = "beszel";
        url = "http://localhost:${toString reverseProxy.ports.beszel}";
        version = 2;
        systemId = "Test";
        fields = [
          "cpu"
          "memory"
          "disk"
          "network"
        ];
      };
    };
  };

  libFailures =
    let
      results = lib.runTests libTests;
    in
    lib.optional (results != [ ]) (lib.generators.toPretty { } results);
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        "homelab/homepage-proxy-ports" = mkCheck pkgs "homelab/homepage-proxy-ports" proxyFailures;
        "homelab/homepage-lib" = mkCheck pkgs "homelab/homepage-lib" libFailures;
      }
      // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-systemd-homepage" = mkSystemdCheck host pkgs "homelab/validate-systemd-homepage" [
          "homepage-generate-config.service"
        ];
      };
    };
}
