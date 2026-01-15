{ lib, ... }:
{
  flake.modules.darwin.laptop = {
    system.defaults = {
      CustomSystemPreferences = {
        finder = {
          DisableAllAnimations = true;
          FXEnableExtensionChangeWarning = false;
          QuitMenuItem = true;
          ShowExternalHardDrivesOnDesktop = false;
          ShowHardDrivesOnDesktop = false;
          ShowMountedServersOnDesktop = false;
          ShowPathbar = true;
          ShowRemovableMediaOnDesktop = false;
          _FXSortFoldersFirst = true;
        };
      };
    };
  };

  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin = {
        defaults = {
          NSGlobalDomain = {
            AppleShowAllExtensions = true;
          };

          "com.apple.finder" = {
            ShowPathbar = 1;
            ShowSidebar = 1;
            ShowStatusBar = true;
            FXDefaultSearchScope = "SCcf";
          };
        };
      };
    };
}
