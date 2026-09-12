{ lib, ... }:
{
  options.flake.meta.aiProviders = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          endpoint = lib.mkOption {
            type = lib.types.str;
            description = "API endpoint URL.";
          };
          apiKeyEnv = lib.mkOption {
            type = lib.types.str;
            description = "Environment variable name for the API key.";
          };
          models = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    description = "Human-readable model name.";
                  };
                  modalities = lib.mkOption {
                    type = lib.types.nullOr (
                      lib.types.submodule {
                        options = {
                          input = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            default = [ "text" ];
                          };
                          output = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            default = [ "text" ];
                          };
                        };
                      }
                    );
                    default = null;
                  };
                  options = lib.mkOption {
                    type = lib.types.attrsOf lib.types.anything;
                    default = { };
                  };
                  variants = lib.mkOption {
                    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
                    default = { };
                  };
                };
              }
            );
            default = { };
          };
        };
      }
    );
    default = { };
    description = "AI provider records shared across modules.";
  };
}
