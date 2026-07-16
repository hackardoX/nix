{
  configurations.nixos.HomeLab.module = {
    nixpkgs.hostPlatform = "aarch64-linux";
    time.timeZone = "Europe/Paris";
  };
}
