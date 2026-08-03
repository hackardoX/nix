{ config, lib, ... }:
{
  flake.modules.nixos.homelab-security =
    nixosArgs@{ pkgs, ... }:
    let
      ntfy = config.flake.meta.ntfy;
      autheliaDataDir = "/var/lib/data/authelia";

      banNotifyScript = ''
        set -euo pipefail

        DB=${autheliaDataDir}/db.sqlite3
        STATE=/var/lib/authelia-ntfy/last_ids
        TOKEN_FILE=${nixosArgs.config.services.onepassword-secrets.secretPaths.alertingNtfyToken}

        last_user=0
        last_ip=0
        if [[ -f "$STATE" ]]; then
          read -r last_user last_ip < "$STATE"
        fi

        token=$(cat "$TOKEN_FILE")

        send() {
          local kind="$1" value="$2" until="$3"
          curl -sf -o /dev/null \
            -H "Authorization: Bearer $token" \
            -H "Title: Authelia: $kind banned" \
            -H "Priority: high" \
            -H "Tags: warning,skull" \
            -d "$kind '$value' banned by Authelia until $until" \
            ${ntfy.url}/${ntfy.topic} \
            || logger -t authelia-ntfy "ntfy notification failed for $kind $value"
        }

        while IFS='|' read -r id time username; do
          send User "$username" "$time"
          last_user=$id
        done < <(sqlite3 "$DB" "SELECT id, time, username FROM banned_user WHERE id > $last_user ORDER BY id;")

        while IFS='|' read -r id time ip; do
          send IP "$ip" "$time"
          last_ip=$id
        done < <(sqlite3 "$DB" "SELECT id, time, ip FROM banned_ip WHERE id > $last_ip ORDER BY id;")

        echo "$last_user $last_ip" > "$STATE"
      '';
    in
    {
      systemd.services.authelia-ntfy = {
        description = "Send ntfy notifications for new Authelia bans";
        after = [ "opnix-secrets.service" ];
        wants = [ "opnix-secrets.service" ];
        path = [
          pkgs.sqlite
          pkgs.curl
          pkgs.util-linux
        ];
        serviceConfig = {
          Type = "oneshot";
          User = config.flake.meta.authelia.user;
          Group = config.flake.meta.authelia.group;
          StateDirectory = "authelia-ntfy";
          ExecStart = "${lib.getExe pkgs.bash} -c ${lib.escapeShellArg banNotifyScript}";
        };
      };

      systemd.timers.authelia-ntfy = {
        description = "Poll Authelia database for new bans";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1m";
          OnUnitActiveSec = "5m";
          AccuracySec = "1m";
        };
      };
    };
}
