{ lib, ... }:
{
  options.flake.meta.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          hostName = lib.mkOption {
            type = lib.types.str;
            description = "The host's networking.hostName.";
          };

          domain = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "The host's networking.domain.";
          };

          user = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Primary SSH user on the host.";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 22;
            description = "SSH port of the host.";
          };

          publicKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "SSH host public key. Hosts without one are excluded from the SSH mesh, mirroring the previous services.openssh.publicKey gate.";
          };
        };
      }
    );
    default = { };
    description = "Host records shared across nix-darwin, NixOS and home-manager modules. Readable from every partition without evaluating host configurations.";
  };
}
