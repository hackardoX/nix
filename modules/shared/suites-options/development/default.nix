{
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  ${namespace}.suites.development = {
    enable = mkEnableOption "common development configuration";
    aiEnable = mkEnableOption "ai development configuration";
    containerization = {
      enable = mkEnableOption "containerization development configuration";
      variants = mkOption {
        type = types.listOf (
          types.enum [
            "podman"
            "docker"
          ]
        );
        default = [ ];
        description = "Container managers to use";
        example = [ "docker" ];
      };
    };
    nixEnable = mkEnableOption "nix development configuration";
    sqlEnable = mkEnableOption "sql development configuration";
    git = {
      user = mkOption {
        type = types.str;
        description = "Git username for commits";
        example = "johndoe";
      };
      email = mkOption {
        type = types.str;
        description = "Git email for commits";
        example = "john@example.com";
      };
    };
    ssh = {
      authorizedKeys = mkOption {
        type = types.listOf types.str;
        description = "List of SSH public keys to be added to authorized_keys";
        example = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC..."
        ];
      };
      allowedSigners = mkOption {
        type = types.listOf types.str;
        description = "List of SSH allowed signers";
        example = [
          "<custom>@<email>.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsOzI1TFwbRy..."
        ];
      };
      knownHosts = mkOption {
        type = types.listOf types.str;
        description = "List of SSH known hosts";
        example = [
          "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsOzI1TFwbRy..."
        ];
      };
      hosts = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              hostname = mkOption {
                type = types.nullOr types.str;
                description = "The hostname to connect to.";
                example = "123.168.48.86";
                default = null;
              };
              user = mkOption {
                type = types.nullOr types.str;
                description = "The user to connect as.";
                example = "ubuntu";
                default = null;
              };
              forwardAgent = mkOption {
                type = types.nullOr types.bool;
                description = "Whether to forward the authentication agent.";
                default = null;
              };
              identitiesOnly = mkOption {
                type = types.nullOr types.bool;
                description = "Whether to use only the specified identities.";
                default = null;
              };
              identityFile = mkOption {
                type = types.nullOr types.str;
                description = "The identity file to use.";
                example = "/path/to/identity/file";
                default = null;
              };
              port = mkOption {
                type = types.nullOr types.int;
                description = "The port to connect to.";
                example = 22;
                default = null;
              };
            };
          }
        );
        description = "Additional SSH hosts configuration.";
        default = { };
        example = {
          "example.com" = {
            hostname = "example.com";
            user = "example";
            forwardAgent = true;
            identitiesOnly = true;
            identityFile = "/path/to/identity/file";
            port = 2222;
          };
          "example2.com" = {
            hostname = "example2.com";
          };
        };
      };
    };
  };
}
