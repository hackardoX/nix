{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        settings = {
          font-size = 14;
          background-blur-radius = 20;
          mouse-hide-while-typing = true;
          window-decoration = true;
          macos-option-as-alt = true;
          keybind = [
            "alt+left=unbind"
            "alt+right=unbind"
          ];
        };
        package = pkgs.ghostty-bin;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };
    };
}
