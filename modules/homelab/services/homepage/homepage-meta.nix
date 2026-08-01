{ lib, ... }:
{
  options.flake.homepage.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          category = lib.mkOption { type = lib.types.str; };
          name = lib.mkOption { type = lib.types.str; };
          description = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          icon = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          href = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          widget = lib.mkOption {
            type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
            default = null;
          };
          ping = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          siteMonitor = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          showStats = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
          };
          statusStyle = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          container = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          dockerServer = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          dockerSocketProxyPort = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
          };
          pingPort = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
          };
        };
      }
    );
    default = { };
  };
}
