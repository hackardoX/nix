{ config, lib, ... }:
{
  options.flake.meta.authelia-policies = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          default_policy = lib.mkOption {
            type = lib.types.str;
            default = "deny";
            description = "Default policy when no rules match.";
          };
          rules = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule {
                options = {
                  subject = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "List of subjects (e.g., 'group:admin').";
                  };
                  policy = lib.mkOption {
                    type = lib.types.str;
                    description = "Policy to apply when subject matches (e.g., 'two_factor').";
                  };
                };
              }
            );
            description = "Rules for this authorization policy.";
          };
        };
      }
    );
    default = { };
    description = "Custom authorization policies for OIDC clients.";
    example = lib.literalExpression ''
      {
        admin-only = {
          default_policy = "deny";
          rules = [{ subject = ["group:admin"]; policy = "two_factor"; }];
        };
      }
    '';
  };

  config = {
    flake.meta.authelia-policies.admin-only = {
      default_policy = "deny";
      rules = [
        {
          subject = [ "group:admin" ];
          policy = "two_factor";
        }
      ];
    };

    flake.modules.nixos.homelab-security = {
      services.authelia.instances.default.settings.identity_providers.oidc.authorization_policies =
        lib.mapAttrs
          (_: policy: {
            default_policy = policy.default_policy;
            rules = map (rule: {
              subject = rule.subject;
              policy = rule.policy;
            }) policy.rules;
          })
          config.flake.meta.authelia-policies;
    };
  };
}
