{ lib, ... }:
{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    {
      home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        "Desktop/.keep".text = "";
        "Documents/.keep".text = "";
        "Downloads/.keep".text = "";
        "Music/.keep".text = "";
        "Pictures/.keep".text = "";
        "Videos/.keep".text = "";
        # "Pictures/.profile".source = pkgs.user-icon;
      };
    };
}
