{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.checks) mkSystemdCheck;

  # Everything the NixOS fail2ban module and homelab-security put under
  # /etc/fail2ban (jail.local, paths-nixos.conf, the ntfy action, the packaged
  # jail.conf, filter.d and action.d). Sources that are globs over the package
  # (action.d, filter.d) are expanded by the shell.
  fail2banEtc = lib.filterAttrs (n: _: lib.hasPrefix "fail2ban/" n) host.environment.etc;

  copyEntry =
    name: entry:
    let
      dst = "$work/${name}";
      src = entry.source;
    in
    if lib.hasInfix "*" (toString src) then
      ''
        mkdir -p "${dst}"
        cp ${src} "${dst}/"
      ''
    else
      ''
        mkdir -p "$(dirname "${dst}")"
        cp ${src} "${dst}"
      '';

  validateFail2ban =
    pkgs:
    pkgs.runCommand "homelab-validate-fail2ban"
      {
        nativeBuildInputs = [ host.services.fail2ban.package ];
      }
      ''
        set -euo pipefail
        work=$PWD/work
        mkdir -p $work
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList copyEntry fail2banEtc)}

        # fail2ban -t needs the logpath of every enabled jail to exist, and the
        # sandbox has no /var/log. Redirect them into the build dir.
        chmod u+w $work/fail2ban/jail.local
        sed -i -e "s#/var/log/#$work/log/#g" $work/fail2ban/jail.local
        sed -n 's/^logpath[[:space:]]*=[[:space:]]*//p' $work/fail2ban/jail.local | tr ' ' '\n' | while IFS= read -r log; do
          mkdir -p "$(dirname "$log")"
          touch "$log"
        done

        fail2ban-client -c $work/fail2ban -t
        touch $out
      '';
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-fail2ban" = validateFail2ban pkgs;
        "homelab/validate-systemd-fail2ban" = mkSystemdCheck host pkgs "homelab/validate-systemd-fail2ban" [
          "fail2ban.service"
        ];
      };
    };
}
