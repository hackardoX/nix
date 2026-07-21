{ config, ... }: {
  flake.modules.nixos.ssh = nixosArgs: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        AllowUsers = [
          nixosArgs.config.system.primaryUser
          config.flake.meta.users.deploy.name
        ];
      };
      allowSFTP = false;
    };
  };
}
