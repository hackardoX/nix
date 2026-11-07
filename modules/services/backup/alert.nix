{
  lib,
  ...
}:
{
  flake.modules.homeManager.backup =
    hmArgs@{ pkgs, ... }:
    let
      cfg = hmArgs.config.services.backup;
      inherit (hmArgs) osConfig;
      ntfy = osConfig.services.ntfy-notify or { };
      tokenPath = osConfig.sops.secrets."alerting/ntfy_token".path;
      topicPath = osConfig.sops.secrets."alerting/ntfy_topic".path;
      hostName = osConfig.networking.hostName or "host";

      notifyScript =
        pkgs: token_path: topic_path: url: host:
        pkgs.writeShellScript "backup-notify" ''
          set -euo pipefail

          instance="$1"
          result="''${instance%%.*}"
          name="''${instance#*.}"

          token_path="${token_path}"
          url="${url}/$("${pkgs.coreutils}/bin/cat" "${topic_path}")"
          host="${host}"

          case "$result" in
            success)
              title="Backup succeeded: ''${name}"
              message="''${host}: backup ''${name} completed successfully"
              priority="low"
              tags="white_check_mark"
              ;;
            failure)
              title="Backup FAILED: ''${name}"
              message="''${host}: backup ''${name} failed. Check: journalctl --user -u restic-backups-''${name}.service"
              priority="high"
              tags="warning"
              ;;
            *)
              exit 0
              ;;
          esac

          token="$("${pkgs.coreutils}/bin/cat" "$token_path")"

          # The URL (it holds the topic) and the token go on stdin so they stay
          # out of the process list; printf is a shell builtin.
          printf 'url = "%s"\nheader = "Authorization: Bearer %s"\n' "$url" "$token" \
            | "${pkgs.curl}/bin/curl" -sf -o /dev/null -K - \
            -H "Title: $title" \
            -H "Priority: $priority" \
            -H "Tags: $tags" \
            -d "$message" || "${lib.getExe' pkgs.util-linux "logger"}" -t backup-alert "ntfy notification failed for ''${name}"
        '';
    in
    {
      options.services.backup.notify = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg.jobs != { };
          description = "Notify via ntfy when backups succeed or fail";
        };

        url = lib.mkOption {
          type = lib.types.str;
          default = ntfy.url or "https://ntfy.sh";
          description = "ntfy server URL";
        };

        topicFile = lib.mkOption {
          type = lib.types.path;
          default = topicPath;
          description = "Path to a file containing the ntfy topic";
        };

        tokenFile = lib.mkOption {
          type = lib.types.path;
          default = tokenPath;
          description = "Path to a file containing the ntfy access token";
        };
      };

      config = lib.mkIf cfg.notify.enable {
        systemd.user.services = lib.mkMerge [
          {
            "backup-notify@" = {
              Unit.Description = "Send ntfy notification about a backup result";
              Service = {
                Type = "oneshot";
                ExecStart = toString (notifyScript pkgs cfg.notify.tokenFile cfg.notify.topicFile cfg.notify.url hostName) + " %i";
              };
            };
          }
          (lib.concatMapAttrs (
            jobName: jobCfg:
            lib.genAttrs (map (provider: "restic-backups-${jobName}-${provider}") jobCfg.providers) (name: {
              Unit = {
                OnSuccess = [ "backup-notify@success.${lib.removePrefix "restic-backups-" name}.service" ];
                OnFailure = [ "backup-notify@failure.${lib.removePrefix "restic-backups-" name}.service" ];
              };
            })
          ) cfg.jobs)
        ];
      };
    };
}
