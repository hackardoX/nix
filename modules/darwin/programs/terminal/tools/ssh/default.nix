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
    knownHosts = mkOpt (lib.types.listOf lib.types.str) [ ] "Known hosts.";
    extraConfig = mkOpt lib.types.str "" "Extra configuration to apply.";
  };

  # TODO: Always disabled for now. Decide later if this should be removed.
  config = lib.mkIf (cfg.enable && false) {
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
