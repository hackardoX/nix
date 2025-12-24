{ config, ... }:
let
  modules = [
    "desktop"
    "dev"
    "iso"
    "laptop"
    "office"
    "shell"

    "bluetooth"
    "opentabletdriver"
    "podman"
    "printing"
  ];
in
{
  flake = {
    images.homelab = config.flake.nixosConfigurations.homelab.config.system.build.isoImage;
    nixosConfigurations.homelab = config.flake.lib.mkSystems.linux "homelab";
    modules.nixos."hosts/homelab" = {
      imports = config.flake.lib.loadNixosAndHmModuleForUser config modules;
    };
  };
}
