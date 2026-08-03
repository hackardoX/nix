{
  self,
  config,
  ...
}:
let
  ntfyUrl = "https://ntfy.sh";
  ntfyTopic = "homelab-alerts";
in
{
  flake.modules.nixos.base =
    nixosArgs@{ pkgs, ... }:
    let
      tokenPath = nixosArgs.config.services.onepassword-secrets.secretPaths.autoUpgradeNtfyToken;

      upgradeNotifyScript = pkgs.writeShellScript "ntfy-upgrade-notify" ''
        set -euo pipefail

        token_path="${tokenPath}"
        url="${ntfyUrl}/${ntfyTopic}"
        host="${nixosArgs.config.networking.hostName}"

        case "$1" in
          success)
            gen="$("${pkgs.nix}/bin/nix-env" --profile /nix/var/nix/profiles/system --list-generations | "${pkgs.coreutils}/bin/tail" -n 1)"
            set -- $gen
            generation="$1"
            title="NixOS: auto-upgrade succeeded"
            message="''${host} updated to generation ''${generation}"
            priority="low"
            tags="white_check_mark"
            ;;
          failure)
            title="NixOS: auto-upgrade failed"
            message="''${host} auto-upgrade failed at $("${pkgs.coreutils}/bin/date" -Is). Check: journalctl -u nixos-upgrade"
            priority="high"
            tags="warning"
            ;;
          *)
            exit 0
            ;;
        esac

        token="$("${pkgs.coreutils}/bin/cat" "$token_path")"

        "${pkgs.curl}/bin/curl" -sf -o /dev/null \
          -H "Authorization: Bearer $token" \
          -H "Title: $title" \
          -H "Priority: $priority" \
          -H "Tags: $tags" \
          -d "$message" \
          "$url" || "${pkgs.util-linux}/bin/logger" -t ntfy-upgrade "ntfy notification failed: $title"
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

      services.onepassword-secrets.secrets.autoUpgradeNtfyToken = {
        path = "/run/secrets/auto_upgrade_ntfy_token";
        reference = "op://Homelab/Alerting/NTFY/token";
        services.nixos-upgrade.restart = false;
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
