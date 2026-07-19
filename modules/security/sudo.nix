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
          Defaults env_keep += "SSH_AUTH_SOCK"
        '';
      };
      pam = {
        services = {
          sudo = {
            unixAuth = false;
            sshAgentAuth = true;
          };
          su = {
            unixAuth = false;
            sshAgentAuth = true;
          };
        };
        sshAgentAuth = {
          enable = true;
          authorizedKeysFiles = [ "/etc/ssh/authorized_sudo_keys/%u" ];
        };
      };
    };
  };
}
