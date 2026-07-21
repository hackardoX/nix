{
  flake.modules.darwin.base = {
    system.defaults.NSGlobalDomain.AppleICUForce24HourTime = true;
    system.defaults.menuExtraClock = {
      Show24Hour = true;
      ShowDayOfWeek = true;
      ShowSeconds = false;
      ShowDate = 0;
    };
  };
}
