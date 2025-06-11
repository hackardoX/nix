{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.art = {
    enable = lib.mkEnableOption "art configuration";
  };
}
