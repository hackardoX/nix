{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.checks) mkCheck mkSystemdCheck;

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

  # --- crowdsec-wiring ---------------------------------------------------
  # CrowdSec only works if three things agree: the file Caddy writes, the file
  # CrowdSec reads, and the key file Caddy's bouncer reads. None of them is
  # checked by a unit starting, so check them here.

  crowdsec = host.services.crowdsec;
  caddyConfig = host.services.caddy.globalConfig + host.services.caddy.extraConfig;
  acquiredFiles = lib.concatMap (a: a.filenames or [ ]) crowdsec.settings.acquisitions;
  caddyAccessLog = "/var/lib/caddy/access.log";
  bouncerKey = "/var/lib/crowdsec-caddy-bouncer/api-key";

  crowdsecFailures =
    lib.optional (
      !lib.elem caddyAccessLog acquiredFiles
    ) "services.crowdsec has no acquisition for ${caddyAccessLog} (has: ${toString acquiredFiles})"
    ++ lib.optional (
      !lib.hasInfix "output file ${caddyAccessLog} {" caddyConfig
    ) "Caddy does not write its access log to ${caddyAccessLog}"
    ++ lib.optional (
      !lib.hasInfix "mode 0640" caddyConfig
    ) "Caddy's access log is not group readable (mode 0640), crowdsec cannot read it"
    ++ lib.optional (
      !lib.elem "caddy" crowdsec.extraGroups
    ) "services.crowdsec.extraGroups lacks caddy, so it cannot read ${caddyAccessLog}"
    ++ lib.optional (
      !lib.hasInfix "{file.${bouncerKey}}" caddyConfig
    ) "Caddy's crowdsec bouncer does not read its key from ${bouncerKey}"
    ++ lib.optional (
      !lib.hasInfix "order crowdsec first" caddyConfig
    ) "Caddyfile does not order the crowdsec handler"
    ++ lib.optional (
      !lib.hasInfix "${bouncerKey}" host.systemd.services.crowdsec-caddy-bouncer-register.script
    ) "crowdsec-caddy-bouncer-register does not write ${bouncerKey}"
    ++ lib.optional (
      host.services.crowdsec.settings.config.api.server.listen_uri != "127.0.0.1:8080"
    ) "crowdsec LAPI listens on ${host.services.crowdsec.settings.config.api.server.listen_uri}, Caddy expects 127.0.0.1:8080"
    ++ lib.optional (
      (host.services.crowdsec.settings.config.prometheus.listen_addr or "") != "127.0.0.1"
    ) "crowdsec metrics are not bound to 127.0.0.1";

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
      checks = {
        "homelab/crowdsec-wiring" = mkCheck pkgs "homelab/crowdsec-wiring" crowdsecFailures;
      }
      // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-fail2ban" = validateFail2ban pkgs;
        "homelab/validate-systemd-crowdsec" =
          mkSystemdCheck host pkgs "homelab/validate-systemd-crowdsec"
            [
              "crowdsec.service"
              "crowdsec-setup.service"
              "crowdsec-firewall-bouncer.service"
              "crowdsec-firewall-bouncer-register.service"
              "crowdsec-caddy-bouncer-register.service"
            ];
        "homelab/validate-systemd-fail2ban" = mkSystemdCheck host pkgs "homelab/validate-systemd-fail2ban" [
          "fail2ban.service"
        ];
      };
    };
}
