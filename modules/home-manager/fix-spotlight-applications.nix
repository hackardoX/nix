{ inputs, lib, ... }:
{
  flake.modules.homeManager.base =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      home.activation = {
        copyNixApps = inputs.home-manager.lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          # Create directory for the applications
          run mkdir -p "$HOME/Applications/Nix Apps"
          # Remove old entries
          run rm -rf "$HOME/Applications/Nix Apps"/*
          # Get the target of the symlink from home-manager
          NIXAPPS="$newGenPath/home-path/Applications"
          # For each application
          for app_link in "$NIXAPPS"/*; do
            if [ -d "$app_link" ] || [ -L "$app_link" ]; then
                # Resolve the symlink to get the actual app in the nix store
                app_source=$(readlink -f "$app_link")
                appname=$(basename "$app_source")
                target="$HOME/Applications/Nix Apps/$appname"
                
                # Create the basic structure
                run mkdir -p "$target"
                run mkdir -p "$target/Contents"
                
                # Copy the Info.plist file
                if [ -f "$app_source/Contents/Info.plist" ]; then
                  run mkdir -p "$target/Contents"
                  run cp -f "$app_source/Contents/Info.plist" "$target/Contents/"
                fi
                
                # Copy icon files
                if [ -d "$app_source/Contents/Resources" ]; then
                  run mkdir -p "$target/Contents/Resources"
                  run find "$app_source/Contents/Resources" -name "*.icns" -exec cp -f {} "$target/Contents/Resources/" \;
                fi
                
                # Symlink the MacOS directory (contains the actual binary)
                if [ -d "$app_source/Contents/MacOS" ]; then
                  run ln -sfn "$app_source/Contents/MacOS" "$target/Contents/MacOS"
                fi
                
                # Symlink other directories
                for dir in "$app_source/Contents"/*; do
                  dirname=$(basename "$dir")
                  if [ "$dirname" != "Info.plist" ] && [ "$dirname" != "Resources" ] && [ "$dirname" != "MacOS" ]; then
                    run ln -sfn "$dir" "$target/Contents/$dirname"
                  fi
                done
              fi
              done
        '';
      };
    };
}
