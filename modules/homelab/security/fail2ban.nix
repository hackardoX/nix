{ config, lib, ... }:
let
  inherit (config.flake.meta) fail2ban;
in
{
  flake.meta.fail2ban = {
    owner = "fail2ban";
    group = "fail2ban";
  };

  flake.modules.nixos.security =
    nixosArgs@{ pkgs, ... }:
    {
      users.users.${fail2ban.owner} = {
        isSystemUser = true;
        group = fail2ban.group;
      };

      users.groups.${fail2ban.group} = { };

      environment.etc."fail2ban/filter.d/caddy-auth.conf".text = ''
        [Definition]
        failregex = ^<HOST>.*"(GET|POST|OPTION).*" (4[0-9][0-9])[ \d]*$
        ignoreregex =
      '';

      environment.etc."fail2ban/action.d/sendmail-common.local".text = ''
        [Init]
        mailcmd = sendmail --account=fail2ban -f "<sender>" "<dest>"
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
          extraPackages = [ pkgs.msmtp ];
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
              action = ''
                %(action_mwl)s
              '';
            };
            caddy-auth.settings = {
              enabled = true;
              port = "http,https";
              filter = "caddy-auth";
              logpath = "/var/log/caddy/access.log";
              maxretry = 5;
              findtime = "10m";
              bantime = "1h";
              sender = "fail2ban@${config.flake.meta.reverse-proxy.domain}";
              destemail = config.flake.meta.users.${nixosArgs.config.system.primaryUser}.email;
              action = ''
                %(action_mwl)s
              '';
            };
          };
        };

        onepassword-secrets.secrets = {
          resendApiKey = {
            path = "/run/secrets/resend_api_key";
            reference = "op://HomeLab/Resend/Fail2ban/api key";
            owner = fail2ban.owner;
            group = fail2ban.group;
            services = [ "fail2ban" ];
          };
        };
      };

      systemd.services.fail2ban.serviceConfig.StateDirectory = lib.mkForce "data/fail2ban";
    };
}
