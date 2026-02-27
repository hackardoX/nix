{ self, ... }:
{
  flake.packages.aarch64-linux.linux-builder =
    self.darwinConfigurations.Andrea-MacBook-Air.config.nix.linux-builder.config.system.build.toplevel;

  flake.modules.darwin.laptop = {
    nix = {
      linux-builder = {
        enable = true;
        ephemeral = true;
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        maxJobs = 4;
        config = {
          virtualisation = {
            darwin-builder = {
              diskSize = 20 * 1024;
              memorySize = 8 * 1024;
            };
            cores = 6;
          };
          boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
        };
      };
      settings.builders-use-substitutes = true;
      distributedBuilds = true;
    };
  };
}
