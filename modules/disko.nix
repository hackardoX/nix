{ self, inputs, ... }: {
  imports = [
    inputs.disko.flakeModules.default
  ];

  flake.diskoConfigurations = builtins.mapAttrs (hostname: hostConfig: {
    disko.devices = hostConfig.config.disko.devices;
  }) self.nixosConfigurations;
}
