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
lib.mkIf aiEnabled {
  home = {
    file = {
      ".continue/config.yaml".source = ./config.yaml;
    };

    activation.generateContinueConfig = lib.mkIf (config.${namespace}.security.opnix.enable or false) (
      home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        sed -i \
          -e "s|__CODESTRAL_API_KEY__|$(<${config.programs.onepassword-secrets.secretPaths.codestralApiKey})|" \
          -e "s|__KIMI_API_KEY__|$(<${config.programs.onepassword-secrets.secretPaths.kimiApiKey})|" \
          -e "s|__COHERE_API_KEY__|$(<${config.programs.onepassword-secrets.secretPaths.cohereApiKey})|" \
          "$HOME/.continue/config.yaml"
      ''
    );
  };

  ${namespace} = {
    security = {
      opnix = {
        secrets = {
          codestralApiKey = {
            path = ".continue/secrets/codestral_api_key";
            reference = "op://Development/woe3hj5uqm3cog2efpl33h65e4/credential";
            group = "staff";
          };
          cohereApiKey = {
            path = ".continue/secrets/cohere_api_key";
            reference = "op://Development/n7nfmu52z4cor4zsrkdpupxgb4/credential";
            group = "staff";
          };
          kimiApiKey = {
            path = ".continue/secrets/kimi_api_key";
            reference = "op://Development/3z6ja6n6ghzt6s7rwnwphutktm/credential";
            group = "staff";
          };
        };
      };
    };
  };
}
