{
  config,
  lib,
  inputs,
  ...
}:
let
  myReachableHosts =
    # config.flake.nixosConfigurations // config.flake.darwinConfigurations
    config.flake.darwinConfigurations
    |> lib.filterAttrs (
      _name: host:
      !(lib.any isNull [
        host.config.networking.domain
        host.config.networking.hostName
        host.config.services.openssh.publicKey
      ])
    );
  knownHosts = myReachableHosts |> lib.mapAttrsToList (_name: host: host.config.networking.fqdn);
  email = config.flake.meta.users.hackardo.email;
in
{
  flake.modules.homeManager.base =
    { config, pkgs, ... }:
    {
      options.ssh = {
        extraConfig = lib.mkOption {
          type = lib.types.str;
          default = "";
        };
        extraHosts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                hostname = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "The hostname to connect to.";
                  example = "123.168.48.86";
                  default = null;
                };
                user = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "The user to connect as.";
                  example = "ubuntu";
                  default = null;
                };
                forwardAgent = lib.mkOption {
                  type = lib.types.nullOr lib.types.bool;
                  description = "Whether to forward the authentication agent.";
                  default = null;
                };
                identitiesOnly = lib.mkOption {
                  type = lib.types.nullOr lib.types.bool;
                  description = "Whether to use only the specified identities.";
                  default = null;
                };
                identityFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "The identity file to use.";
                  example = "/path/to/identity/file";
                  default = null;
                };
                port = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
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

      config = {
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          matchBlocks =
            myReachableHosts
            |> lib.mapAttrsToList (
              _name: host: {
                "${host.config.networking.fqdn}" = {
                  identityFile = "~/.ssh/keys/infra_ed25519";
                };
              }
            )
            |> lib.concat [
              {
                "*" = {
                  addKeysToAgent = "yes";
                  compression = true;
                  controlMaster = "auto";
                  controlPersist = "30m";
                  forwardAgent = false;
                  hashKnownHosts = true;
                  identitiesOnly = true;
                  identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
                  serverAliveInterval = 60;
                  setEnv.TERM = "xterm-256color";
                };
              }
            ]
            |> lib.concat [ config.ssh.extraHosts ]
            |> lib.mkMerge;
          extraConfig = ''
            StreamLocalBindUnlink yes
          ''
          + config.ssh.extraConfig;
        };

        home = {
          # shellAliases = lib.mapAttrs' (system: _: {
          #   name = "ssh-${system}";
          #   value = "ssh ${system}";
          # }) config.hosts;

          file = {
            ".ssh/allowed_signers".text = ''
              ${email} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsOzI1TFwbRy/GgE2/fNJR8B7gfIogp//2kDJ7D1uSB
            '';

          };

          activation.generateKnownHosts = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            PATH=${pkgs.openssh}/bin:$PATH
            known_hosts_file="$HOME/.ssh/known_hosts"
            temp_file="$(mktemp)"

            mkdir -p "$HOME/.ssh"

            ${lib.concatMapStringsSep "\n" (hostname: ''
              echo "Scanning ${hostname}..."
              ssh-keyscan -H "${hostname}" >> "$temp_file" || echo "Failed to scan ${hostname}" >&2
            '') knownHosts}

            if [[ -s "$temp_file" ]]; then
              grep -v '^[[:space:]]*$' "$temp_file" | sort -u > "$known_hosts_file"
              chmod 644 "$known_hosts_file"
              echo "Updated SSH known_hosts with entries from ${toString (lib.length knownHosts)} hostnames"
            else
              echo "No SSH keys were successfully scanned"
            fi

            rm "$temp_file"
          '';
        };
      };
    };
}
