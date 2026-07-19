{ config, ... }:
let
  inherit (config.flake.meta) fail2ban;
in
{
  flake.meta.fail2ban = {
    owner = "fail2ban";
    group = "fail2ban";
  };

  flake.modules.nixos.homelab = nixosArgs: {
    users.users.${fail2ban.owner} = {
      isSystemUser = true;
      group = fail2ban.group;
    };

    users.groups.${fail2ban.group} = { };

    programs.msmtp = {
      enable = true;
      setSendmail = true;
      defaults = {
        port = 587;
        auth = "plain";
        tls = "on";
        tls_starttls = "on";
        account = "fail2ban";
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
        jails = {
          ssh-iptables.settings = {
            enabled = true;
            port = "ssh";
            filter = "sshd";
            logpath = "/var/log/auth.log";
            maxretry = 3;
            bantime = "24h";
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
          reference = "op://Development/Resend/api key";
          owner = fail2ban.owner;
          group = fail2ban.group;
          services = [ "fail2ban" ];
        };
      };
    };
  };
}
