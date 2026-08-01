{
  flake.modules.darwin.base = {
    system.defaults.NSGlobalDomain."com.apple.sound.beep.feedback" = 0;
    system.defaults.NSGlobalDomain."com.apple.sound.beep.volume" = 0.0;
  };
}
