{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.social = {
    enable = lib.mkEnableOption "social configuration";
  };
}
