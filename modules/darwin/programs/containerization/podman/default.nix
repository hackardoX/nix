{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    types
    ;
  inherit (lib.${namespace})
    mkOpt
    ;
  cfg = config.${namespace}.programs.containerization.podman;
in
{
  options.${namespace}.programs.containerization.podman = {
    enable = mkEnableOption "podman";
    provider = mkOpt (types.enum [
      "qemu"
      "applehv"
      "libkrun"
    ]) "" "Provider to use.";
  };

  config = lib.mkIf cfg.enable {
    homebrew.brews = lib.mkIf (cfg.provider == "" || cfg.provider == "libkrun") [
      "krunvm"
    ];
  };
}
