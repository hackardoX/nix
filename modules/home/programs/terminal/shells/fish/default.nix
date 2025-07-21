{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.shell.fish;
in
{
  options.${namespace}.programs.terminal.shell.fish = {
    enable = lib.mkEnableOption "fish";
  };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
    };
  };
}
