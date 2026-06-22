{ ... }:
{
  flake.modules.darwin.laptop = {
    security = {
      pam.services = {
        sudo_local = {
          reattach = true;
          touchIdAuth = true;
        };
      };
      sudo.extraConfig = "Defaults timestamp_timeout=30";
    };
  };

  flake.modules.nixos.homelab = {
    security = {
      sudo = {
        execWheelOnly = true;
        extraConfig = ''
          Defaults timestamp_timeout=0
        '';
      };
      pam = {
        services.sudo.unixAuth = false;
        sshAgentAuth = {
          enable = true;
          authorizedKeysFiles = [ "/etc/ssh/authorized_sudo_keys.%u" ];
        };
      };
    };
    systemd.tmpfiles.rules = [
      "d /etc/ssh/authorized_sudo_keys 0755 root root -"
    ];
  };
}
