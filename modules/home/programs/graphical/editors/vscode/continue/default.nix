{
  config,
  inputs,
  lib,
  namespace,
  ...
}:
let
  inherit (inputs) home-manager;
  aiEnabled = config.${namespace}.suites.development.aiEnable;
in
{
  home = {
    file = lib.mkIf aiEnabled {
      ".continue/config.yaml".source = ./config.yaml;
    };

    activation.generateContinueConfig = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      sed -i \
        -e "s|__CODESTRAL_API_KEY__|$(<${config.programs.onepassword-secrets.secretPaths.codestralApiKey})|" \
        -e "s|__KIMI_API_KEY__|$(<${config.programs.onepassword-secrets.secretPaths.kimiApiKey})|" \
        -e "s|__COHERE_API_KEY__|$(<${config.programs.onepassword-secrets.secretPaths.cohereApiKey})|" \
        "$HOME/.continue/config.yaml"
    '';
  };
}
