{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  hmUsers = host.home-manager.users;
  inherit (config.flake.lib.checks) mkCheck;
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

  # --- homepage-widget-files ---------------------------------------------
  # A widget key written as {{HOMEPAGE_FILE_X}} is only replaced if the
  # container has HOMEPAGE_FILE_X set to a path that is mounted into it.
  # Otherwise Homepage sends the literal text, which looks like a bad key.

  container = hmUsers.homepage.services.podman.containers.homepage;
  widgetFileRefs = lib.unique (
    lib.concatMap (m: lib.optionals (lib.isList m) m) (
      builtins.split "[{][{](HOMEPAGE_FILE_[A-Z0-9_]+)[}][}]" (
        builtins.toJSON (
          lib.mapAttrsToList (_: svc: {
            inherit (svc) widget widgets;
          }) homepageServices
        )
      )
    )
  );

  widgetFileFailures = lib.concatMap (
    name:
    let
      path = container.environment.${name} or null;
    in
    if path == null then
      [ "widgets use {{${name}}}, but the homepage container has no ${name} environment variable" ]
    else
      lib.optional (
        !lib.any (v: lib.hasInfix ":${path}:" v) container.volumes
      ) "${name} points to ${path}, which is not mounted into the homepage container"
  ) widgetFileRefs;

  # --- homepage-lib ------------------------------------------------------

  libTests = {
    testBeszelWidget = {
      expr = config.flake.lib.beszel.mkWidget { systemId = "Test"; };
      expected = {
        type = "beszel";
        url = "http://localhost:${toString reverseProxy.ports.beszel}";
        version = 2;
        username = "{{HOMEPAGE_FILE_BESZEL_USER}}";
        password = "{{HOMEPAGE_FILE_BESZEL_PASSWORD}}";
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
        "homelab/homepage-widget-files" =
          mkCheck pkgs "homelab/homepage-widget-files" widgetFileFailures;
        "homelab/homepage-lib" = mkCheck pkgs "homelab/homepage-lib" libFailures;
      };
    };
}
