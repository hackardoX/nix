{ config, ... }:
{
  flake.meta.users.hetzner = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "Hetzner HomeLab";
    name = "hetzner";
    uid = 1001;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKjfrZIUY652nVzjjhhhukZoU3RCdws951XOb1PKEWJu hetzner"
    ];
  };

  flake.modules.nixos.hetzner =
    { pkgs, ... }:
    {
      users.users.${config.flake.meta.users.hetzner.name} = {
        inherit (config.flake.meta.users.hetzner) description uid;
        isNormalUser = true;
        group = config.flake.meta.users.hetzner.name;
        shell = pkgs.zsh;
        hashedPassword = "$y$j9T$eFjRG1wVzfAXzCCa2nD05.$.p8T4gfUxacJwCapOI9MuPLDBbL4tmHIrj4SYqvKTO5";
        extraGroups = [
          "wheel"
          "onepassword-secrets"
        ];
        openssh.authorizedKeys.keys = config.flake.meta.users.hetzner.authorizedKeys;
      };

      users.groups.${config.flake.meta.users.hetzner.name} = {
        gid = config.flake.meta.users.hetzner.uid;
      };
    };
}
