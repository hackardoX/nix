{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.programs.containerization.orbstack;
in
{
  options.${namespace}.programs.containerization.orbstack = {
    enable = mkEnableOption "orbstack";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [
      "orbstack"
    ];
  };
}
