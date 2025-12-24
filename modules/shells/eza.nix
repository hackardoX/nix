{
  lib,
  ...
}:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      programs.eza = {
        enable = true;
        enableBashIntegration = true;
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
        la = lib.mkForce "${lib.getExe pkgs.eza} -lah --tree";
        ls = lib.mkForce "${lib.getExe pkgs.eza}";
        tree = lib.mkForce "${lib.getExe pkgs.eza} --tree --icons=always";
      };
    };
}
