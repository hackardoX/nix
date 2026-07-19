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
      sudo-rs = {
        enable = true;
        execWheelOnly = true;
        extraConfig = ''
          Defaults timestamp_timeout=0
          Defaults env_keep += "SSH_AUTH_SOCK"
        '';
      };
      pam = {
        rssh = {
          enable = true;
          settings.auth_key_file = "/etc/ssh/authorized_sudo_keys/$ruser";
        };
        services = {
          sudo = {
            rssh = true;
            unixAuth = false;
            sshAgentAuth = true;
          };
          su = {
            rssh = true;
            unixAuth = false;
            sshAgentAuth = true;
          };
        };
      };
    };
  };
}
