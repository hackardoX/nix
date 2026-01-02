{ config, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        settings = {
          font-family = config.fonts.default.family;
          font-size = 14;
          background-blur-radius = 20;
          mouse-hide-while-typing = true;
          # TODO: wait for https://github.com/ghostty-org/ghostty/discussions/5668
          # window-title-font-family = config.fonts.default.family;
          macos-option-as-alt = true;
          keybind = [
            "alt+left=unbind"
            "alt+right=unbind"
          ];
        };
        package = pkgs.ghostty-bin; # Required for Darwin
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };
    };
}
