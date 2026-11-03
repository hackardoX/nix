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
      mock = import ./_vm-test/mock-sops.nix { inherit lib pkgs host; };

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
      checks = {
        # Drift check, not a VM test. The plain mock files must hold exactly the
        # names the host asks for, one file per production sopsFile. Only key
        # names are printed. Encryption is checked by mockSops itself.
        "homelab/sops-mock" =
          let
            wantFiles = lib.escapeShellArgs (
              map (n: "${n}.yaml") (lib.sort lib.lessThan (lib.attrNames mock.groups))
            );
            checkGroup =
              name: g:
              if g.whole then
                ''
                  if ! yq -o json ${mock.mockDir}/${name}.yaml | jq -e 'type == "object" and length > 0' > /dev/null; then
                    echo "${name}: the whole-file secret is empty or not a mapping" >&2
                    fail=1
                  fi
                ''
              else
                ''
                  yq -o json ${mock.mockDir}/${name}.yaml | jq -r 'paths(type != "object") | join("/")' | LC_ALL=C sort > have.txt
                  printf '%s\n' ${lib.escapeShellArgs g.keys} | LC_ALL=C sort > want.txt
                  missing=$(LC_ALL=C comm -23 want.txt have.txt)
                  extra=$(LC_ALL=C comm -13 want.txt have.txt)
                  if [ -n "$missing" ]; then
                    echo "${name}: keys the host needs but the mock lacks:" >&2
                    sed 's/^/  - /' <<< "$missing" >&2
                    fail=1
                  fi
                  if [ -n "$extra" ]; then
                    echo "${name}: keys the mock has but the host does not use:" >&2
                    sed 's/^/  - /' <<< "$extra" >&2
                    fail=1
                  fi
                '';
          in
          pkgs.runCommand "homelab-sops-mock"
            {
              nativeBuildInputs = [
                pkgs.jq
                pkgs.yq-go
              ];
            }
            ''
              set -euo pipefail
              fail=0

              ls ${mock.mockDir} | LC_ALL=C sort > have-files.txt
              printf '%s\n' ${wantFiles} | LC_ALL=C sort > want-files.txt
              if ! cmp -s have-files.txt want-files.txt; then
                echo "_vm-test/mock: files do not match the production sopsFiles in use:" >&2
                LC_ALL=C comm -3 want-files.txt have-files.txt | sed 's/^/  /' >&2
                fail=1
              fi

              ${lib.concatStringsSep "\n" (lib.mapAttrsToList checkGroup mock.groups)}

              [ "$fail" -eq 0 ] || exit 1
              touch $out
            '';
      }
      // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
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
                  mock
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
