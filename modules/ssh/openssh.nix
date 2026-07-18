{
  flake.modules.nixos.homelab = nixosArgs: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        AllowUsers = [ nixosArgs.config.system.primaryUser ];
      };
      allowSFTP = false;
    };
  };
}
