{
  flake.modules.darwin.base = {
    system.defaults.CustomUserPreferences."com.apple.HIToolbox" =
      let
        keyboard = {
          id = 15000;
          name = "USInternational-PC";
        };
      in
      {
        AppleCurrentKeyboardLayoutInputSourceID = "com.apple.keylayout.${keyboard.name}";
        AppleInputSourceHistory = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = keyboard.id;
            "KeyboardLayout Name" = keyboard.name;
          }
        ];
        AppleEnabledInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = keyboard.id;
            "KeyboardLayout Name" = keyboard.name;
          }
        ];
        AppleSelectedInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = keyboard.id;
            "KeyboardLayout Name" = keyboard.name;
          }
        ];
      };
  };
}
