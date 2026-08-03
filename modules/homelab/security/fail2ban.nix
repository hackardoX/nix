{ config, lib, ... }:
let
  inherit (config.flake.meta) fail2ban;
  inherit (config.flake.meta) ntfy;
in
{
  flake.meta.fail2ban = {
    owner = "fail2ban";
    group = "fail2ban";
  };

  flake.modules.nixos.homelab-security =
    nixosArgs@{ pkgs, ... }:
    let
      cfg = nixosArgs.config.homelab.fail2ban;
    in
    {
      options.homelab.fail2ban = {
        notificationMethod = lib.mkOption {
          type = lib.types.enum [
            "email"
            "ntfy"
          ];
          default = "email";
          description = "How fail2ban sends ban/unban alerts";
        };
      };

      config = {
        users.users.${fail2ban.owner} = {
          isSystemUser = true;
          inherit (fail2ban) group;
        };

        users.groups.${fail2ban.group} = { };

        environment.etc."fail2ban/action.d/sendmail-common.local".text = ''
          [Init]
          mailcmd = sendmail --account=fail2ban -f "<sender>" "<dest>"
        '';

        environment.etc."fail2ban/action.d/ntfy.conf".text = ''
          [Definition]
          norestored = true

          ntfy_topic = ${ntfy.topic}
          ntfy_url = ${ntfy.url}
          ntfy_token = ${nixosArgs.config.services.onepassword-secrets.secretPaths.alertingNtfyToken}

          actionstart = TOKEN=$(cat <ntfy_token>); curl -sf -o /dev/null -H "Authorization: Bearer $TOKEN" -H "Title: Fail2ban: <name>" -H "Priority: low" -H "Tags: rocket" -d "Jail <name> started" "<ntfy_url>/<ntfy_topic>" || logger -t fail2ban "ntfy notification failed for start"
          actionstop = TOKEN=$(cat <ntfy_token>); curl -sf -o /dev/null -H "Authorization: Bearer $TOKEN" -H "Title: Fail2ban: <name>" -H "Priority: low" -H "Tags: stop_sign" -d "Jail <name> stopped" "<ntfy_url>/<ntfy_topic>" || logger -t fail2ban "ntfy notification failed for stop"
          actioncheck =
          actionban = TOKEN=$(cat <ntfy_token>); curl -sf -o /dev/null -H "Authorization: Bearer $TOKEN" -H "Title: Fail2ban: <name>" -H "Priority: high" -H "Tags: warning,skull" -d "Banned <ip> in <name> after <failures> failed attempts" "<ntfy_url>/<ntfy_topic>" || logger -t fail2ban "ntfy notification failed for ban <ip>"
          actionunban = TOKEN=$(cat <ntfy_token>); curl -sf -o /dev/null -H "Authorization: Bearer $TOKEN" -H "Title: Fail2ban: <name>" -H "Priority: default" -H "Tags: white_check_mark" -d "Unbanned <ip> in <name>" "<ntfy_url>/<ntfy_topic>" || logger -t fail2ban "ntfy notification failed for unban <ip>"
        '';

        programs.msmtp = {
          enable = true;
          setSendmail = true;
          defaults = {
            port = 587;
            auth = "plain";
            tls = "on";
            tls_starttls = "on";
          };
          accounts.fail2ban = {
            host = "smtp.resend.com";
            user = "resend";
            passwordeval = "cat ${nixosArgs.config.services.onepassword-secrets.secretPaths.resendApiKey}";
            from = "fail2ban@${config.flake.meta.reverse-proxy.domain}";
          };
        };

        services = {
          fail2ban = {
            enable = true;
            maxretry = 3;
            bantime = "24h";
            daemonSettings.Definition.dbfile = lib.mkForce "/var/lib/data/fail2ban/fail2ban.sqlite3";
            extraPackages = [
              pkgs.msmtp
              pkgs.curl
              pkgs.whois
            ];
            jails = {
              ssh-iptables.settings = {
                enabled = true;
                port = "ssh";
                filter = "sshd";
                logpath = "/var/log/auth.log";
                maxretry = 3;
                bantime = "1w";
                sender = "fail2ban@${config.flake.meta.reverse-proxy.domain}";
                destemail = config.flake.meta.users.${nixosArgs.config.system.primaryUser}.email;
                action = if cfg.notificationMethod == "email" then "%(action_mwl)s" else "ntfy";
              };
            };
          };

          onepassword-secrets.secrets = {
            resendApiKey = {
              path = "/run/secrets/resend_api_key";
              reference = "op://HomeLab/Resend/Fail2ban/api key";
              inherit (fail2ban) owner group;
              services = [ "fail2ban" ];
            };
          };
        };

        systemd.services.fail2ban.serviceConfig.StateDirectory = lib.mkForce "data/fail2ban";
      };
    };
}
