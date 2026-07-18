{ lib, ... }: {
  flake.modules.nixos.homelab = nixosArgs: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        AllowUsers = lib.mkMerge [ nixosArgs.config.system.primaryUser ];
      };
      allowSFTP = false;
    };
  };
}
