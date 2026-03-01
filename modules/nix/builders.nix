{ inputs, ... }:
let
  baseLinuxBuilder = {
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
    };
  };
in
{
  flake.packages.aarch64-darwin.linux-builder =
    (inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ { nix.linux-builder = baseLinuxBuilder; } ];
    }).config.nix.linux-builder.package;

  flake.modules.darwin.laptop = {
    nix = {
      linux-builder = baseLinuxBuilder // {
        config = baseLinuxBuilder.config // {
          boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
        };
      };
      settings.builders-use-substitutes = true;
      distributedBuilds = true;
    };
  };
}
