{ inputs, ... }:
{
  flake.modules.homeManager.laptop =
    { pkgs, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];
      programs.spicetify = {
        enable = true;
        enabledCustomApps = with spicePkgs.apps; [
          historyInSidebar
          marketplace
          ncsVisualizer
          reddit
        ];
        enabledExtensions = with spicePkgs.extensions; [
          hidePodcasts
          shuffle
          betterGenres
          spicyLyrics
        ];
        enabledSnippets = [
          "${pkgs.writeText "rounded-now-playing-bar.css" ''
            :root{ --border-radius-1: 8px; }
            .Root__now-playing-bar, .Root__now-playing-bar footer {
              border-radius: var(--border-radius-1) !important;
            }
          ''}"

          "${pkgs.writeText "remove-gradient.css" ''
            .main-entityHeader-background, 
            .main-entityHeader-background.main-entityHeader-overlay, 
            .main-entityHeader-backgroundColor {
              background-color: transparent !important;
              background-image: none !important;
            }

            .main-actionBarBackground-background,
            .playlist-playlist-actionBarBackground-background {
              background-color: transparent !important;
              background-image: none !important;
            }

            .main-home-homeHeader {
              background-color: transparent !important;
              background-image: none !important;
            }
          ''}"
        ];
        theme = spicePkgs.themes.catppuccin;
        colorScheme = "macchiato";
      };

      home.activation.disableSpotifyUpdates =
        inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
          ''
            SPOTIFY_UPDATE_DIR="$HOME/Library/Application Support/Spotify/PersistentCache/Update"

            if ! /usr/bin/stat -f "%Sf" "$SPOTIFY_UPDATE_DIR" 2> /dev/null | grep -q uchg; then
              rm -rf "$SPOTIFY_UPDATE_DIR"
              mkdir -p "$SPOTIFY_UPDATE_DIR"
              /usr/bin/chflags uchg "$SPOTIFY_UPDATE_DIR"
            fi
          '';
    };
}
