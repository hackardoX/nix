{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (lib) mkOption types;

  cfg = config.${namespace}.programs.terminal.editors.neovim;
in
{
  options.${namespace}.programs.terminal.editors.neovim = {
    enable = lib.mkEnableOption "neovim";
    default = mkBoolOpt true "Whether to set Neovim as the session EDITOR";
    extraModules = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "Additional nixvim modules to extend the khanelivim configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      sessionVariables = {
        EDITOR = lib.mkIf cfg.default "nvim";
        MANPAGER = "nvim -c 'set ft=man bt=nowrite noswapfile nobk shada=\\\"NONE\\\" ro noma' +Man! -o -";
      };

      shellAliases = {
        v = "${pkgs.nvim}";
      };

      packages = [
        pkgs.nvrh
      ];
    };
  };
}
