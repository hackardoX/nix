{
  lib,
  namespace,
  ...
}:
{
  ${namespace}.suites.games = {
    enable = lib.mkEnableOption "games configuration";
  };
}
