{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.checks) mkCheck;

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
      checks."homelab/persistence" = mkCheck pkgs "homelab/persistence" persistenceFailures;
    };
}
