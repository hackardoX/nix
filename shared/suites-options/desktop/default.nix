{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.desktop = {
    enable = lib.mkEnableOption "common desktop configuration";
  };
}
