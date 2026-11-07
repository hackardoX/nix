{ config, ... }:
{
  flake.modules.nixos.homelab-security =
    nixosArgs@{ pkgs, ... }:
    let
      ntfy = nixosArgs.config.services.ntfy-notify;
      autheliaDataDir = "/var/lib/data/authelia";
    in
    {
      systemd.services.authelia-ntfy = {
        description = "Send ntfy notifications for new Authelia bans";
        path = [
          pkgs.sqlite
          pkgs.curl
          pkgs.util-linux
        ];
        serviceConfig = {
          Type = "oneshot";
          User = config.flake.meta.users.authelia.name;
          Group = config.flake.meta.users.authelia.primaryGroup;
          StateDirectory = "authelia-ntfy";
        };
        script = ''
          set -euo pipefail

          DB=${autheliaDataDir}/db.sqlite3
          STATE=/var/lib/authelia-ntfy/last_ids
          TOKEN_FILE=${nixosArgs.config.sops.secrets."alerting/ntfy_token".path}
          TOPIC_FILE=${nixosArgs.config.sops.secrets."alerting/ntfy_topic".path}

          last_user=0
          last_ip=0
          if [[ -f "$STATE" ]]; then
            read -r last_user last_ip < "$STATE"
          fi

          token=$(cat "$TOKEN_FILE")
          url="${ntfy.url}/$(cat "$TOPIC_FILE")"

          send() {
            local kind="$1" value="$2" until="$3"
            # The URL (it holds the topic) and the token go on stdin so they
            # stay out of the process list; printf is a shell builtin.
            printf 'url = "%s"\nheader = "Authorization: Bearer %s"\n' "$url" "$token" \
              | curl -sf -o /dev/null -K - \
              -H "Title: Authelia: $kind banned" \
              -H "Priority: high" \
              -H "Tags: warning,skull" \
              -d "$kind '$value' banned by Authelia until $until" \
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
