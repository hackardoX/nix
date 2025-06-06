{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.common = {
    enable = lib.mkEnableOption "common configuration";
    rosettaEnable = lib.mkEnableOption "enable rosetta";
  };
}
