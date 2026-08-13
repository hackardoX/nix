{
  self,
  config,
  lib,
  ...
}:
{
  flake.modules.nixos.base =
    nixosArgs@{ pkgs, ... }:
    let
      ntfy = nixosArgs.config.services.ntfy-notify;
      tokenPath = nixosArgs.config.services.onepassword-secrets.secretPaths.alertingNtfyToken;

      upgradeNotifyScript = pkgs.writeShellScript "ntfy-upgrade-notify" ''
        set -euo pipefail

        token_path="${tokenPath}"
        url="${ntfy.url}/${ntfy.topic}"
        host="${nixosArgs.config.networking.hostName}"
        journal_url="${config.flake.meta.reverse-proxy.hosts.logs}"

        case "$1" in
          success)
            gen="$("${lib.getExe' pkgs.nix "nix-env"}" --profile /nix/var/nix/profiles/system --list-generations | "${lib.getExe' pkgs.coreutils "tail"}" -n 1)"
            set -- $gen
            generation="$1"
            title="NixOS: auto-upgrade succeeded"
            message="''${host} updated to generation ''${generation}"
            priority="low"
            tags="white_check_mark"
            ;;
          failure)
            title="NixOS: auto-upgrade failed"
            message="''${host} auto-upgrade failed at $("${lib.getExe' pkgs.coreutils "date"}" -Is). Logs: https://''${journal_url}"
            priority="high"
            tags="warning"
            ;;
          *)
            exit 0
            ;;
        esac

        token="$("${lib.getExe' pkgs.coreutils "cat"}" "$token_path")"

        "${lib.getExe' pkgs.curl "curl"}" -sf -o /dev/null \
          -H "Authorization: Bearer $token" \
          -H "Title: $title" \
          -H "Priority: $priority" \
          -H "Tags: $tags" \
          -d "$message" \
          "$url" || "${lib.getExe' pkgs.util-linux "logger"}" -t ntfy-upgrade "ntfy notification failed: $title"
      '';
    in
    {
      system.autoUpgrade = {
        enable = self ? rev;
        flake = config.flake.meta.uri;
        upgrade = false;
        dates = "03:00";
        rebootWindow = {
          lower = "02:00";
          upper = "04:00";
        };
      };

      systemd.services.nixos-upgrade.unitConfig = {
        OnSuccess = [ "ntfy-upgrade-notify@success.service" ];
        OnFailure = [ "ntfy-upgrade-notify@failure.service" ];
      };

      systemd.services."ntfy-upgrade-notify@" = {
        description = "Send ntfy notification about a NixOS auto-upgrade result";
        after = [ "opnix-secrets.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${upgradeNotifyScript} %i";
        };
      };
    };

  flake.modules.darwin.base = {
    system.defaults = {
      CustomUserPreferences = {
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          AutomaticDownload = 1;
          CriticalUpdateInstall = 1;
          ScheduleFrequency = 1;
        };
      };
    };
  };
}
