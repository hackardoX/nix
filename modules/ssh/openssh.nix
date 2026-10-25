{
  flake.modules.nixos.ssh = nixosArgs: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        AllowUsers = [
          nixosArgs.config.system.primaryUser
        ];
      };
      allowSFTP = false;
      authorizedKeysFiles = [ "/run/secrets/%u/authorized_key" ];
    };
  };
}
