{ ... }:
{
  flake.modules.darwin.dev = {
    system.defaults.CustomUserPreferences."com.apple.Safari" = {
      IncludeDevelopMenu = true;
    };
  };
}
