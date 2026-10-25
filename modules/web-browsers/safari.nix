{
  flake.modules.darwin.safari = {
    system.defaults.CustomUserPreferences."com.apple.Safari" = {
      IncludeDevelopMenu = true;
    };
  };
}
