{ config, lib, ... }:
let
  # Names come from the evaluated host; the node itself is the partition's
  # deferred module (same closure as lib.nixosSystem in modules/configurations).
  # The main partition cannot evaluate it: disko and nixos-apple-silicon are
  # only inputs of the homelab partition.
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  hostModule = config.partitions.homelab.module.configurations.nixos.HomeLab-CI.module;

  ownerOf = s: if s.owner == null then "root" else s.owner;
  groupOf = s: if s.group == null then "root" else s.group;

  # Users whose rootless podman units the VM test brings up and checks. They keep
  # lingering so their user managers start at boot; every other lingering user
  # stays off to keep the emulated boot short.
  testedUsers = [
    "immich"
    "tandoor"
  ];
  serviceUsers = lib.genAttrs testedUsers (
    n:
    lib.throwIf (!host.home-manager.users ? ${n})
      "vm-test: testedUsers entry '${n}' is not a home-manager user of HomeLab-CI"
      host.home-manager.users.${n}
  );
  userInfo = name: h: {
    inherit name;
    uid = host.users.users.${name}.uid;
    units = map (c: "podman-${c}.service") (lib.attrNames (h.services.podman.containers or { }));
    secretFiles = lib.filter (c: c != null) (
      lib.mapAttrsToList (
        c: cc:
        if (cc.secrets or { }) != { } then
          "/run/user/${toString host.users.users.${name}.uid}/podman-secrets/${c}"
        else
          null
      ) (h.services.podman.containers or { })
    );
  };

  users = lib.mapAttrsToList userInfo serviceUsers;

  # Data for script.sh: one entry per line, no empty lines (the shell `read`
  # loops would otherwise see an empty name or unit).
  octalMode = s: lib.head (builtins.match "0*([0-7]+)" s.mode);
  secretLines = lib.mapAttrsToList (
    _: s: "${s.path} ${ownerOf s}:${groupOf s}:${octalMode s}"
  ) host.sops.secrets;
  oidcLines = map (n: "${config.flake.lib.authelia.hashedSecretsDir}/${n}_oidc_secret") (
    lib.attrNames config.flake.meta.oidc-clients
  );
  userLines = map (u: "${u.name} ${toString u.uid}") users;
  userUnitLines = lib.concatMap (u: map (unit: "${u.name} ${unit}") u.units) users;
  userFileLines = lib.concatMap (u: u.secretFiles) users;
in
{
  perSystem =
    { pkgs, ... }:
    let
      # Not writeShellApplication: it would restrict PATH inside the VM.
      script = pkgs.writeTextFile {
        name = "homelab-vm-smoke.sh";
        text =
          lib.replaceStrings
            [ "@IMMICH_SECRET@" "@SECRETS@" "@OIDC_SECRETS@" "@USERS@" "@USER_UNITS@" "@USER_FILES@" ]
            [
              host.sops.secrets."immich/db_password".path
              (lib.concatStringsSep "\n" secretLines)
              (lib.concatStringsSep "\n" oidcLines)
              (lib.concatStringsSep "\n" userLines)
              (lib.concatStringsSep "\n" userUnitLines)
              (lib.concatStringsSep "\n" userFileLines)
            ]
            (builtins.readFile ./_vm-test/script.sh);
        checkPhase = ''
          shellcheck --shell=sh "$target"
        '';
        derivationArgs.nativeBuildInputs = [ pkgs.shellcheck ];
      };
    in
    {
      checks = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/vm-activation" = pkgs.testers.runNixOSTest {
          name = "homelab-vm-activation";
          # Spike only: the Linux builder does not advertise nixos-test, and KVM
          # is not needed to build the closure. Revisit before booting the VM.
          requiredFeatures = {
            kvm = false;
            nixos-test = false;
          };
          # The repo's base module sets nixpkgs.config, which read-only node pkgs forbid.
          node.pkgsReadOnly = false;
          # The driver's root-shell connect() has a fixed 300 s window that starts
          # on the first command. Wait for the backdoor's console line first, so
          # that window only starts once the shell is about to answer.
          globalTimeout = 2400;
          nodes.machine = {
            imports = [
              hostModule
              (import ./_vm-test/overrides.nix {
                inherit
                  lib
                  pkgs
                  host
                  testedUsers
                  ;
              })
            ];
          };
          # The VM mounts the host /nix/store (read-only), so ${script} is readable.
          testScript = ''
            from datetime import timedelta

            machine.start()
            machine.wait_for_console_text("connecting to host", timeout=timedelta(minutes=25))
            machine.wait_for_unit("multi-user.target", timeout=timedelta(minutes=20))
            print(machine.succeed("sh ${script}"))
          '';
        };
      };
    };
}
