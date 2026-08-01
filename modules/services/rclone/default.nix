{ lib, ... }:
let
  polyModule = {
    options.services.rclone.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      internal = true;
      description = "Marker that the system rclone module is active";
    };

    config = {
      users.groups.rclone = { };
      services.rclone.enable = true;
    };
  };
in
{
  flake.modules.homeManager.rclone = hmArgs: {
    options.services.rclone.remotes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Which rclone remotes to enable for this user";
    };

    config = {
      programs.rclone.enable = true;

      assertions = [
        {
          assertion = (hmArgs.osConfig or { }).services.rclone.enable or false;
          message = ''
            The home-manager rclone module requires the system-level rclone module
            to be imported in the host configuration.

            Add one of the following to your host imports:
              imports = [ config.flake.modules.nixos.rclone ];   # For NixOS
              imports = [ config.flake.modules.darwin.rclone ];  # For Darwin
          '';
        }
      ];
    };
  };

  flake.modules.nixos.rclone = polyModule;
  flake.modules.darwin.rclone = lib.mkMerge [
    polyModule
    {
      homebrew.casks = [ "macfuse" ];
    }
  ];
}
