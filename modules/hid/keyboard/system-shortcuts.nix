{ lib, ... }:
{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          "com.apple.symbolichotkeys" = {
            AppleSymbolicHotKeys = {
              # 60: Ctrl+Space (Previous Input Source)
              "60" = {
                enabled = false;
              };
              # 61: Ctrl+Opt+Space (Next Input Source)
              "61" = {
                enabled = false;
              };
              # 64: Cmd+Space (Spotlight Search)
              "64" = {
                enabled = false;
              };
            };
          };
        };
      };
    };
}
