{ lib, ... }:
{
  flake.modules.nixos.hardening =
    { config, ... }:
    {
      config = {
        networking.firewall.enable = true;

        services = {
          openssh = {
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
            };
            allowSFTP = true;
            extraConfig = ''
              X11Forwarding no
              AllowAgentForwarding no
            '';
          };

          fail2ban = {
            enable = true;
            maxretry = 3;
            bantime = "24h";
            bantime-increment = {
              enable = true;
              multipliers = "1 2 4 8 16 32 64";
              maxtime = "168h";
            };

            jails = {
              ssh-iptables.settings = {
                enabled = true;
                port = "ssh";
                filter = "sshd";
                # This action will trigger the notification script below
                action = ''
                  iptables-multiport[name=SSH, port="ssh", protocol=tcp]
                '';
                # notification-webhook[name=SSH]'';
              };
            };
          };
        };

        nix.settings.allowed-users = [ "root" ];

        environment.defaultPackages = lib.mkForce [ ];

        security = {
          auditd.enable = true;
          audit = {
            enable = true;
            rules = [
              "-a exit,always -F arch=b64 -S execve"
            ];
          };
          sudo.extraRules = [
            {
              users = [ config.system.primaryUser ];
              commands = [
                { command = "/run/current-system/sw/bin/nixos-rebuild"; }
              ];
            }
          ];
        };

        boot.kernel.sysctl = {
          "kernel.dmesg_restrict" = 1;
          "kernel.kptr_restrict" = 2;
          "net.ipv4.conf.all.rp_filter" = 1;
          "net.ipv4.conf.all.accept_source_route" = 0;
          "net.ipv4.tcp_syncookies" = 1;
          "kernel.yama.ptrace_scope" = 1;
          "net.ipv4.conf.all.send_redirects" = 0;
          "net.ipv4.conf.default.send_redirects" = 0;
        };
      };
    };

  flake.modules.darwin.hardening = { }; # TODO: create an hardening for darwin as well
}
