{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.music = {
    enable = lib.mkEnableOption "common music configuration";
  };
}
