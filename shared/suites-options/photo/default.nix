{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.photo = {
    enable = lib.mkEnableOption "photo configuration";
  };
}
