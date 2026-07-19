{
  inputs,
  lib,
  ...
}:
{
  configurations.nixos.HomeLab.module =
    {
      modulesPath,
      ...
    }:
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
            "tg3"
          ];

          network = {
            enable = true;
            ssh = {
              enable = true;
              port = 2222;
              authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINITBgeUtBDMKomSpjla72kbHvh9CYCV7yHVoAfGBIUK root@homelab-initrd"
              ];
              hostKeys = [
                "/etc/secrets/initrd/ssh_host_ed25519_key"
              ];
            };
          };
          secrets = lib.mkForce {
            "/etc/secrets/initrd/ssh_host_ed25519_key" = "/persist/etc/secrets/initrd/ssh_host_ed25519_key";
          };
        };
        kernelParams = [ "ip=dhcp" ];
      };

      # TODO: Remove this once the issue is fixed
      # https://github.com/NixOS/nixpkgs/issues/204619
      powerManagement.cpuFreqGovernor = lib.mkForce null;
    };
}
