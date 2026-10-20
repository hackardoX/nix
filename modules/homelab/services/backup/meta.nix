{ lib, ... }:
{
  options.flake.meta.backup.repos = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          uri = lib.mkOption {
            type = lib.types.str;
            description = "Restic repository URI.";
          };
          passwordFile = lib.mkOption {
            type = lib.types.str;
            description = "Path to the file holding the repository encryption password.";
          };
        };
      }
    );
    default = { };
    description = "Restic backup repositories managed by backrest, keyed by repository id.";
  };
}
