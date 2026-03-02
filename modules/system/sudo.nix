{ lib, ... }:
{
  flake.modules.darwin.laptop.security = {
    pam.services = {
      sudo_local = {
        reattach = true;
        touchIdAuth = true;
      };
    };

    # Set sudo timeout to 30 minutes
    sudo.extraConfig = "Defaults    timestamp_timeout=30";
  };

  flake.modules.nixos.homelab =
    { config, ... }:
    {
      security.sudo.extraRules = lib.mkAfter [
        {
          users = [ config.system.primaryUser ];
          commands = [
            # {
            #   command = "/nix/store/*/bin/switch-to-configuration";
            #   options = [
            #     "NOPASSWD"
            #     "SETENV"
            #   ];
            # }
            # {
            #   command = "/run/current-system/sw/bin/nixos-rebuild";
            #   options = [
            #     "NOPASSWD"
            #     "SETENV"
            #   ];
            # }
            # {
            #   command = "/run/current-system/sw/bin/systemctl";
            #   options = [
            #     "NOPASSWD"
            #     "SETENV"
            #   ];
            # }
          ];
        }
      ];
    };
}
