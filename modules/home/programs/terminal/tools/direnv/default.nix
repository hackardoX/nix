{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.programs.terminal.tools.direnv;
in
{
  options.${namespace}.programs.terminal.tools.direnv = {
    enable = lib.mkEnableOption "direnv";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = enabled;
      enableZshIntegration = config.${namespace}.programs.terminal.shell.zsh.enable;
      silent = true;
    };
  };
}
