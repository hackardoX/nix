{
  flake.modules.darwin.base = {
    system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
    system.defaults.NSGlobalDomain.KeyRepeat = 2;
    system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
  };
}
