{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.checks) mkCheck mkSystemdCheck;
  reverseProxy = config.flake.meta.reverse-proxy;
  homepageServices = config.flake.meta.homepage.services;

  # Hosts without a Caddy virtual host on HomeLab-CI, on purpose.
  vhostExceptions = {
    # No vhost yet; its module lives in services/_monitoring, which is not loaded.
    grafana = "no Caddy vhost";
    # Served through the Cloudflare tunnel, not Caddy.
    ssh = "served by the Cloudflare tunnel";
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

  # --- validators (build-time, aarch64-linux only) -----------------------
  # Each one runs an upstream tool on a file HomeLab-CI generates. They need
  # the host platform, so they are only defined for aarch64-linux.

  # `caddy validate` on the generated Caddyfile, with the plugin build.
  # nixpkgs only runs `caddy fmt` (a syntax parse) at build time, so module
  # errors (unknown directive, bad acme_dns token, bad plugin config) would
  # otherwise only show up when the service starts. Sandbox-only changes:
  #   /run/secrets/*  -> dummy files; the cloudflare module checks the token
  #                      shape, so the dummy is 40 hex chars
  #   /var/lib/caddy, /var/log/caddy -> build dir (caddy opens the access log
  #                      and the storage dir while validating)
  #   maxmind db_path -> MaxMind's GeoLite2 test database from the pinned
  #                      libmaxminddb source, copied to every db_path. This
  #                      proves the config and the plugin load; it does not
  #                      prove the real GeoIP database is present or valid
  validateCaddy =
    pkgs:
    pkgs.runCommand "homelab-validate-caddy"
      {
        nativeBuildInputs = [
          host.services.caddy.package
          pkgs.openssl
        ];
      }
      ''
        set -euo pipefail
        work=$PWD/work
        mkdir -p $work/secrets $work/state $work/log $work/home $work/mmdb
        cp --no-preserve=mode ${host.services.caddy.configFile} $work/Caddyfile

        sed -i \
          -e "s#/run/secrets/#$work/secrets/#g" \
          -e "s#/var/lib/caddy#$work/state#g" \
          -e "s#/var/log/caddy#$work/log#g" \
          $work/Caddyfile

        sed -n "s#.*\($work/secrets/[^ {}\"]*\).*#\1#p" $work/Caddyfile | sort -u | while IFS= read -r secret; do
          mkdir -p "$(dirname "$secret")"
          openssl rand -hex 20 > "$secret"
        done

        tar -xzf ${pkgs.libmaxminddb.src} -C $work/mmdb --wildcards '*/t/maxmind-db/test-data/GeoLite2-Country-Test.mmdb'
        sed -n 's/.*db_path "\([^"]*\)".*/\1/p' $work/Caddyfile | sort -u | while IFS= read -r db; do
          mkdir -p "$(dirname "$db")"
          cp $work/mmdb/*/t/maxmind-db/test-data/GeoLite2-Country-Test.mmdb "$db"
        done

        export HOME=$work/home XDG_DATA_HOME=$work/home/data XDG_CONFIG_HOME=$work/home/config
        caddy validate --adapter caddyfile --config $work/Caddyfile
        touch $out
      '';
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        "homelab/ports" = mkCheck pkgs "homelab/ports" portFailures;
        "homelab/hosts-vhosts" = mkCheck pkgs "homelab/hosts-vhosts" vhostFailures;
      }
      // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-caddy" = validateCaddy pkgs;
        "homelab/validate-systemd-caddy" = mkSystemdCheck host pkgs "homelab/validate-systemd-caddy" [
          "caddy.service"
        ];
      };
    };
}
