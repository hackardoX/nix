{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.services.ollama;
in
{
  options.${namespace}.services.ollama = {
    enable = lib.mkEnableOption "ollama";
    enableDebug = lib.mkEnableOption "debug";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      host = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "0.0.0.0";

      environmentVariables = lib.optionalAttrs cfg.enableDebug {
        OLLAMA_DEBUG = "1";
      };
    };
  };
}
