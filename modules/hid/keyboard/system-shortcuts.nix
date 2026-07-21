{
  flake.modules.darwin.base = {
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "60" = {
          enabled = false;
        };
        "61" = {
          enabled = false;
        };
        "64" = {
          enabled = false;
        };
      };
    };
  };
}
