{
  config,
  lib,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.programs.terminal.tools.ssh;

  myHosts = import ./hosts.nix {
    inherit
      config
      lib
      inputs
      namespace
      ;
  };

in
{
  options.${namespace}.programs.terminal.tools.ssh = {
    enable = lib.mkEnableOption "ssh support";
    knownHosts = mkOpt (lib.types.attrsOf (
      lib.types.submodule {
        options = {
          hostNames = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "List of host names.";
            example = [ "github.com" ];
          };
          publicKey = lib.mkOption {
            type = lib.types.str;
            description = "Public key for the host.";
            example = "ssh-rsa AAAAB...";
          };
          publicKeyFile = lib.mkOption {
            type = lib.types.str;
            description = "Path to the public key file for the host.";
            example = "/Users/user/.ssh/id_rsa.pub";
          };
        };
      }
    )) { } "Known hosts.";
    extraConfig = mkOpt lib.types.str "" "Extra configuration to apply.";
  };

  # TODO: Always disabled for now. Decide later if this should be removed.
  config = lib.mkIf (cfg.enable && false) {
    assertions = [
      {
        assertion = lib.all (
          host:
          let
            hasPublicKey = host.publicKey != null;
            hasPublicKeyFile = host.publicKeyFile != null;
          in
          !(hasPublicKey && hasPublicKeyFile)
        ) cfg.knownHosts;
        message = "Each known host must have either a publicKey or a publicKeyFile, but not both.";
      }
    ];
    programs.ssh = {
      inherit (cfg) knownHosts;

      extraConfig = ''
        ${lib.concatStringsSep "\n" (map (host: host.config) (builtins.attrValues myHosts))}

        ${cfg.extraConfig}
      '';
    };

    ${namespace} = {
      home.extraOptions = {
        programs.zsh.shellAliases = lib.foldl (
          aliases: system: aliases // { "ssh-${system}" = "ssh ${system}"; }
        ) { } (builtins.attrNames myHosts);
      };
    };
  };
}
