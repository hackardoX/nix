{
  flake.modules.darwin.laptop = {
    nix.linux-builder = {
      enable = true;
      ephemeral = true;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maxjobs = 4;
      config = {
        virtualisation = {
          darwin-builder = {
            disksize = 20 * 1024;
            memorysize = 8 * 1024;
          };
          cores = 6;
        };
        boot.binfmt.emulatedsystems = [ "x86_64-linux" ];
      };
    };

    nix.settings = {
      builders-use-substitutes = true;
    };

    nix.distributedbuilds = true;
  };
}
