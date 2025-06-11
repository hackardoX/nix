{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.networking = {
    enable = lib.mkEnableOption "networking configuration";
  };
}
