{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.business = {
    enable = lib.mkEnableOption "business configuration";
  };
}
