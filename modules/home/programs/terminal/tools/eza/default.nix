{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let

  cfg = config.${namespace}.programs.terminal.tools.eza;
in
{
  options.${namespace}.programs.terminal.tools.eza = {
    enable = lib.mkEnableOption "eza";
  };

  config = lib.mkIf cfg.enable {
    programs.eza = {
      enable = true;
      package = pkgs.eza;

      enableZshIntegration = true;

      extraOptions = [
        "--group-directories-first"
        "--header"
        "--hyperlink"
        "--follow-symlinks"
      ];

      git = true;
      icons = "auto";
    };

    home.shellAliases = {
      la = lib.mkForce "${lib.getExe config.programs.eza.package} -lah --tree";
      ls = lib.mkForce "${lib.getExe config.programs.eza.package}";
      tree = lib.mkForce "${lib.getExe config.programs.eza.package} --tree --icons=always";
    };
  };
}
