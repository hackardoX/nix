{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.homelab.check) mkCheck;
  reverseProxy = config.flake.meta.reverse-proxy;
  homepageServices = config.flake.meta.homepage.services;

  # Hosts without a Caddy virtual host on HomeLab-CI, on purpose.
  vhostExceptions = {
    # No vhost yet; its module lives in services/_monitoring, which is not loaded.
    grafana = "no Caddy vhost";
    # Served through the Cloudflare tunnel, not Caddy.
    ssh = "served by the Cloudflare tunnel";
  };

  # Service users (linger, home under /var/lib) whose state is not under a
  # persist.directories entry. Each exception needs a reason.
  persistenceExceptions = {
    # Config is regenerated under /var/lib/podman/homepage on every start.
    homepage = "config is regenerated on every start";
    # State lives in /var/lib/data/beszel, a persistent mount.
    beszel = "state lives in /var/lib/data/beszel (persistent mount)";
    # Open question: /var/lib/backrest (operation log) is not persisted.
    backrest = "open question: /var/lib/backrest is not persisted";
  };

  # --- ports -------------------------------------------------------------

  portValues = lib.attrValues reverseProxy.ports;
  duplicatePorts = lib.unique (lib.filter (p: lib.count (x: x == p) portValues > 1) portValues);
  homepagePortRefs = lib.concatLists (
    lib.mapAttrsToList (
      name: svc:
      lib.concatMap
        (
          field:
          lib.optional (svc.${field} != null) {
            inherit name field;
            port = svc.${field};
          }
        )
        [
          "pingPort"
          "dockerSocketProxyPort"
        ]
    ) homepageServices
  );

  portFailures =
    map (
      p:
      "reverse-proxy.ports: port ${toString p} is used by ${
        lib.concatStringsSep ", " (lib.attrNames (lib.filterAttrs (_: v: v == p) reverseProxy.ports))
      }"
    ) duplicatePorts
    ++ map (
      r:
      "homepage.services.${r.name}.${r.field} = ${toString r.port} is not a declared reverse-proxy port"
    ) (lib.filter (r: !lib.elem r.port portValues) homepagePortRefs);

  # --- hosts-vhosts ------------------------------------------------------

  vhostFailures =
    lib.concatLists (
      lib.mapAttrsToList (
        name: domain:
        lib.optional (
          !lib.hasAttr name vhostExceptions && !lib.hasAttr domain host.services.caddy.virtualHosts
        ) "reverse-proxy.hosts.${name} (${domain}) has no services.caddy.virtualHosts entry on HomeLab-CI"
      ) reverseProxy.hosts
    )
    ++ map (n: "vhostExceptions.${n}: no reverse-proxy.hosts entry named '${n}'; stale exception") (
      lib.filter (n: !lib.hasAttr n reverseProxy.hosts) (lib.attrNames vhostExceptions)
    );

  # --- persistence -------------------------------------------------------

  persistEntries = host.boot.initrd.impermanence.persist.directories;
  persistDir = e: if lib.isAttrs e then e.directory else e;
  persistUser = e: if lib.isAttrs e then e.user or null else null;

  # A service user is covered when a persist entry is equal to, or a parent
  # of, its home. The one app-dir rule: a rootless podman app dir
  # /var/lib/podman/<user>, persisted with user = <user>, is accepted for that
  # same user, because these services keep their state there and not in home.
  persistedFor =
    name: home:
    lib.any (
      e:
      home == persistDir e
      || lib.hasPrefix "${persistDir e}/" home
      || (persistUser e == name && persistDir e == "/var/lib/podman/${name}")
    ) persistEntries;

  serviceUsers = lib.filterAttrs (
    _: u: u.linger == true && lib.hasPrefix "/var/lib/" u.home
  ) host.users.users;

  persistenceFailures =
    lib.concatLists (
      lib.mapAttrsToList (
        name: u:
        lib.optional (!lib.hasAttr name persistenceExceptions && !persistedFor name u.home)
          "users.users.${name} (linger, home ${u.home}) has no boot.initrd.impermanence.persist.directories entry; persist it or add it to persistenceExceptions with a reason"
      ) serviceUsers
    )
    ++ map (n: "persistenceExceptions.${n}: no linger service user named '${n}'; stale exception") (
      lib.filter (n: !lib.hasAttr n serviceUsers) (lib.attrNames persistenceExceptions)
    );
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        "homelab/ports" = mkCheck pkgs "ports" portFailures;
        "homelab/hosts-vhosts" = mkCheck pkgs "hosts-vhosts" vhostFailures;
        "homelab/persistence" = mkCheck pkgs "persistence" persistenceFailures;
      };
    };
}
