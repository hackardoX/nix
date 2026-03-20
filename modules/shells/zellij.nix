{ lib, ... }:
let
  zellijBindings =
    bindings:
    builtins.listToAttrs (
      map (
        { keys, action }:
        {
          name =
            "bind "
            + lib.strings.concatMapStrings (k: "\"${k}\" ") (lib.lists.init keys)
            + "\"${lib.lists.last keys}\"";
          value = action;
        }
      ) bindings
    );

  zellijUnbinds = unbindList: {
    ${"unbind" + (lib.strings.concatStrings (map (x: " \"${x}\"") unbindList))} = [ ];
  };
in
{
  flake.modules.homeManager.shell = {
    programs.zellij = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        ui.pane_frames.hide_session_name = false;
        show_startup_tips = false;

        "keybinds clear-defaults=true" = {

          normal =
            (zellijUnbinds [
              "Ctrl p"
              "Ctrl o"
              "Ctrl q"
              "Ctrl h"
            ])
            // (zellijBindings [
              {
                keys = [ "Alt g" ];
                action = {
                  "Run \"lazygit\"" = {
                    floating = true;
                    x = "10%";
                    y = "10%";
                    width = "80%";
                    height = "80%";
                    close_on_exit = true;
                  };
                };
              }
              {
                keys = [ "Alt G" ];
                action = {
                  "Run \"gh-dash\"" = {
                    floating = true;
                    close_on_exit = true;
                    x = "5%";
                    y = "5%";
                    width = "90%";
                    height = "90%";
                  };
                };
              }
            ]);

          locked = zellijBindings [
            {
              keys = [ "Ctrl g" ];
              action = {
                SwitchToMode = "Normal";
              };
            }
          ];

          resize = zellijBindings [
            {
              keys = [ "Ctrl n" ];
              action = {
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [
                "h"
                "Left"
              ];
              action = {
                Resize = "Increase Left";
              };
            }
            {
              keys = [
                "j"
                "Down"
              ];
              action = {
                Resize = "Increase Down";
              };
            }
            {
              keys = [
                "k"
                "Up"
              ];
              action = {
                Resize = "Increase Up";
              };
            }
            {
              keys = [
                "l"
                "Right"
              ];
              action = {
                Resize = "Increase Right";
              };
            }
            {
              keys = [ "H" ];
              action = {
                Resize = "Decrease Left";
              };
            }
            {
              keys = [ "J" ];
              action = {
                Resize = "Decrease Down";
              };
            }
            {
              keys = [ "K" ];
              action = {
                Resize = "Decrease Up";
              };
            }
            {
              keys = [ "L" ];
              action = {
                Resize = "Decrease Right";
              };
            }
            {
              keys = [
                "="
                "+"
              ];
              action = {
                Resize = "Increase";
              };
            }
            {
              keys = [ "-" ];
              action = {
                Resize = "Decrease";
              };
            }
          ];

          pane = zellijBindings [
            {
              keys = [ "Ctrl a" ];
              action = {
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [
                "h"
                "Left"
              ];
              action = {
                MoveFocus = "Left";
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [
                "l"
                "Right"
              ];
              action = {
                MoveFocus = "Right";
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [
                "j"
                "Down"
              ];
              action = {
                MoveFocus = "Down";
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [
                "k"
                "Up"
              ];
              action = {
                MoveFocus = "Up";
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "p" ];
              action = {
                SwitchFocus = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "n" ];
              action = {
                NewPane = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "d" ];
              action = {
                NewPane = "Down";
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "x" ];
              action = {
                CloseFocus = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "z" ];
              action = {
                ToggleFocusFullscreen = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "f" ];
              action = {
                TogglePaneFrames = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "w" ];
              action = {
                ToggleFloatingPanes = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "e" ];
              action = {
                TogglePaneEmbedOrFloating = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "r" ];
              action = {
                SwitchToMode = "RenamePane";
                PaneNameInput = 0;
              };
            }
          ];

          tab = zellijBindings [
            {
              keys = [ "Ctrl t" ];
              action = {
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "r" ];
              action = {
                SwitchToMode = "RenameTab";
                TabNameInput = 0;
              };
            }
            {
              keys = [
                "h"
                "Left"
                "Up"
                "k"
              ];
              action = {
                GoToPreviousTab = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [
                "l"
                "Right"
                "Down"
                "j"
              ];
              action = {
                GoToNextTab = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "n" ];
              action = {
                NewTab = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "x" ];
              action = {
                CloseTab = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "s" ];
              action = {
                ToggleActiveSyncTab = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "b" ];
              action = {
                BreakPane = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "]" ];
              action = {
                BreakPaneRight = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "[" ];
              action = {
                BreakPaneLeft = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "1" ];
              action = {
                GoToTab = 1;
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "2" ];
              action = {
                GoToTab = 2;
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "3" ];
              action = {
                GoToTab = 3;
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "4" ];
              action = {
                GoToTab = 4;
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "5" ];
              action = {
                GoToTab = 5;
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "6" ];
              action = {
                GoToTab = 6;
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "7" ];
              action = {
                GoToTab = 7;
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "8" ];
              action = {
                GoToTab = 8;
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "9" ];
              action = {
                GoToTab = 9;
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "a" ];
              action = {
                ToggleTab = [ ];
                SwitchToMode = "Normal";
              };
            }
          ];

          scroll = zellijBindings [
            {
              keys = [ "Ctrl s" ];
              action = {
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "e" ];
              action = {
                EditScrollback = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "s" ];
              action = {
                SwitchToMode = "EnterSearch";
                SearchInput = [ ];
              };
            }
            {
              keys = [ "G" ];
              action = {
                ScrollToBottom = [ ];
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [
                "j"
                "Down"
              ];
              action = {
                ScrollDown = [ ];
              };
            }
            {
              keys = [
                "k"
                "Up"
              ];
              action = {
                ScrollUp = [ ];
              };
            }
            {
              keys = [
                "Ctrl f"
                "PageDown"
                "Right"
                "l"
              ];
              action = {
                PageScrollDown = [ ];
              };
            }
            {
              keys = [
                "Ctrl b"
                "PageUp"
                "Left"
                "h"
              ];
              action = {
                PageScrollUp = [ ];
              };
            }
            {
              keys = [ "d" ];
              action = {
                HalfPageScrollDown = [ ];
              };
            }
            {
              keys = [ "u" ];
              action = {
                HalfPageScrollUp = [ ];
              };
            }
          ];

          search = zellijBindings [
            {
              keys = [ "Ctrl /" ];
              action = {
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [
                "j"
                "Down"
              ];
              action = {
                ScrollDown = [ ];
              };
            }
            {
              keys = [
                "k"
                "Up"
              ];
              action = {
                ScrollUp = [ ];
              };
            }
            {
              keys = [
                "Ctrl f"
                "PageDown"
                "Right"
                "l"
              ];
              action = {
                PageScrollDown = [ ];
              };
            }
            {
              keys = [
                "Ctrl b"
                "PageUp"
                "Left"
                "h"
              ];
              action = {
                PageScrollUp = [ ];
              };
            }
            {
              keys = [ "d" ];
              action = {
                HalfPageScrollDown = [ ];
              };
            }
            {
              keys = [ "u" ];
              action = {
                HalfPageScrollUp = [ ];
              };
            }
            {
              keys = [ "n" ];
              action = {
                Search = "down";
              };
            }
            {
              keys = [ "p" ];
              action = {
                Search = "up";
              };
            }
            {
              keys = [ "c" ];
              action = {
                SearchToggleOption = "CaseSensitivity";
              };
            }
            {
              keys = [ "w" ];
              action = {
                SearchToggleOption = "Wrap";
              };
            }
            {
              keys = [ "o" ];
              action = {
                SearchToggleOption = "WholeWord";
              };
            }
          ];

          entersearch = zellijBindings [
            {
              keys = [ "Ctrl s" ];
              action = {
                SwitchToMode = "Scroll";
              };
            }
            {
              keys = [ "Esc" ];
              action = {
                SwitchToMode = "Scroll";
              };
            }
            {
              keys = [ "Enter" ];
              action = {
                SwitchToMode = "Search";
              };
            }
          ];

          renametab = zellijBindings [
            {
              keys = [ "Ctrl s" ];
              action = {
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "Esc" ];
              action = {
                UndoRenameTab = [ ];
                SwitchToMode = "Tab";
              };
            }
          ];

          renamepane = zellijBindings [
            {
              keys = [ "Ctrl c" ];
              action = {
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "Esc" ];
              action = {
                UndoRenamePane = [ ];
                SwitchToMode = "Pane";
              };
            }
          ];

          session = zellijBindings [
            {
              keys = [ "Ctrl x" ];
              action = {
                SwitchToMode = "Normal";
              };
            }
            {
              keys = [ "d" ];
              action = {
                Detach = [ ];
              };
            }
            {
              keys = [ "w" ];
              action = {
                "LaunchOrFocusPlugin \"zellij:session-manager\"" = {
                  floating = true;
                  move_to_focused_tab = true;
                };
                SwitchToMode = "Normal";
              };
            }
          ];

          "shared_except \"locked\"" = zellijBindings [
            {
              keys = [ "Ctrl g" ];
              action = {
                SwitchToMode = "Locked";
              };
            }
            {
              keys = [ "Alt n" ];
              action = {
                NewPane = [ ];
              };
            }
            {
              keys = [
                "Alt h"
                "Alt Left"
              ];
              action = {
                MoveFocusOrTab = "Left";
              };
            }
            {
              keys = [
                "Alt l"
                "Alt Right"
              ];
              action = {
                MoveFocusOrTab = "Right";
              };
            }
            {
              keys = [
                "Alt j"
                "Alt Down"
              ];
              action = {
                MoveFocus = "Down";
              };
            }
            {
              keys = [
                "Alt k"
                "Alt Up"
              ];
              action = {
                MoveFocus = "Up";
              };
            }
            {
              keys = [
                "Alt ="
                "Alt +"
              ];
              action = {
                Resize = "Increase";
              };
            }
            {
              keys = [ "Alt -" ];
              action = {
                Resize = "Decrease";
              };
            }
            {
              keys = [ "Alt [" ];
              action = {
                PreviousSwapLayout = [ ];
              };
            }
            {
              keys = [ "Alt ]" ];
              action = {
                NextSwapLayout = [ ];
              };
            }
          ];

          "shared_except \"normal\" \"locked\"" = zellijBindings [
            {
              keys = [
                "Enter"
                "Esc"
              ];
              action = {
                SwitchToMode = "Normal";
              };
            }
          ];
          "shared_except \"pane\" \"locked\"" = zellijBindings [
            {
              keys = [ "Ctrl a" ];
              action = {
                SwitchToMode = "Pane";
              };
            }
          ];
          "shared_except \"resize\" \"locked\"" = zellijBindings [
            {
              keys = [ "Ctrl n" ];
              action = {
                SwitchToMode = "Resize";
              };
            }
          ];
          "shared_except \"scroll\" \"locked\"" = zellijBindings [
            {
              keys = [ "Ctrl s" ];
              action = {
                SwitchToMode = "Scroll";
              };
            }
          ];
          "shared_except \"session\" \"locked\"" = zellijBindings [
            {
              keys = [ "Ctrl x" ];
              action = {
                SwitchToMode = "Session";
              };
            }
          ];
          "shared_except \"tab\" \"locked\"" = zellijBindings [
            {
              keys = [ "Ctrl t" ];
              action = {
                SwitchToMode = "Tab";
              };
            }
          ];
          "shared_except \"renametab\" \"locked\"" = zellijBindings [
            {
              keys = [ "Alt r" ];
              action = {
                SwitchToMode = "RenameTab";
              };
            }
          ];
        };

        plugins = {
          tab-bar.path = "tab-bar";
          status-bar.path = "status-bar";
          strider.path = "strider";
          compact-bar.path = "compact-bar";
        };

        on_force_close = "detach";
        pane_frames = false;
      };
    };
  };
}
