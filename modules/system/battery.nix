{
  flake.modules.darwin.battery = {
    system.defaults.CustomUserPreferences."com.apple.batteryui.charging.mac" = {
      "com.apple.batteryui.charging.mac.prior.limit" = 80;
    };
  };
}
