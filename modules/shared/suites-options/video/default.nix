{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.video = {
    enable = lib.mkEnableOption "video configuration";
  };
}
