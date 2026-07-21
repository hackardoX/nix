{
  flake.modules.darwin.base = {
    system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;

    system.defaults.finder = {
      QuitMenuItem = true;
      ShowExternalHardDrivesOnDesktop = false;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = false;
      ShowStatusBar = true;
      _FXSortFoldersFirst = true;
      FXDefaultSearchScope = "SCcf";
    };

    system.defaults.CustomUserPreferences."com.apple.finder".DisableAllAnimations = true;
    system.defaults.CustomUserPreferences."com.apple.finder".ShowSidebar = true;
  };
}
