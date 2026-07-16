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

      hardware.asahi = {
        enable = true;
        peripheralFirmwareDirectory = ./firmware;
      };

      boot = {
        loader = {
          efi.canTouchEfiVariables = false;
          systemd-boot.enable = true;
        };
        initrd = {
          availableKernelModules = [
            "xhci_pci"
            "usbhid"
            "usb_storage"
            "macb" # Mac Mini M1 1Gbps Ethernet for remote LUKS unlock
          ];

          network = {
            enable = true;
            ssh = {
              enable = true;
              port = 2222;
              inherit (config.flake.meta.users.hal) authorizedKeys;
              hostKeys = [
                nixosArgs.config.services.onepassword-secrets.secretPaths.homeLabInitrdPrivateKey
              ];
            };
          };
        };
        kernelParams = [ "ip=dhcp" ];
      };
    };
}
