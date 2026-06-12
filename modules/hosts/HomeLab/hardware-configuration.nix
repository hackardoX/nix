{
  config,
  inputs,
  ...
}:
{
  configurations.nixos.HomeLab.module =
    {
      modulesPath,
      ...
    }@nixosArgs:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
      ];

      hardware.asahi.peripheralFirmwareDirectory = ./firmware;

      boot = {
        loader = {
          efi.canTouchEfiVariables = false;
          systemd-boot.enable = true;
        };
        initrd = {
          availableKernelModules = [
            "macb" # Mac Mini M1 1Gbps Ethernet for remote LUKS unlock
          ];

          luks.devices."crypted".device = "/dev/disk/by-uuid/d5abab6e-0650-4e5b-8fb4-3a500d196e95";
          network = {
            enable = true;
            ssh = {
              enable = true;
              port = 2222;
              inherit (config.flake.meta.users.hal) authorizedKeys;
              hostKeys = [
                nixosArgs.config.services.onepassword-secrets.secretPaths.homeLabPrivateKey
              ];
              shell = "/bin/cryptsetup-askpass";
            };
          };
        };
        kernelParams = [ "ip=dhcp" ];
      };
    };
}
