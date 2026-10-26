{ config, inputs, ... }:
{
  flake.meta.users.deploy = {
    name = "deploy";
    uid = 2000;
  };

  flake.modules.nixos.deploy = {
    sops.secrets."deploy/authorized_key" = {
      sopsFile = "${inputs.self}/secrets/users/deploy.yaml";
    };
    sops.secrets."deploy/sudo_authorized_key" = {
      sopsFile = "${inputs.self}/secrets/users/deploy.yaml";
      path = "/etc/ssh/deploy/authorized_sudo_keys";
    };

    users.users.${config.flake.meta.users.deploy.name} = {
      isNormalUser = true;
      description = "System deploy user";
      uid = config.flake.meta.users.deploy.uid;
      extraGroups = [
        "wheel"
      ];
    };

    nix.settings.trusted-users = [ config.flake.meta.users.deploy.name ];

    services.openssh.settings.AllowUsers = [ config.flake.meta.users.deploy.name ];
  };
}
