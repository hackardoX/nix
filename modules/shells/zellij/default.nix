{
  flake.modules.homeManager.shell = {
    programs = {
      zellij = {
        enable = true;
        enableZshIntegration = true;
        extraConfig = ''
          ui {
            pane_frames {
              hide_session_name false
            }
          }
          show_startup_tips false

          keybinds clear-defaults=true {
            normal {
              unbind "Ctrl p" "Ctrl o" "Ctrl q" "Ctrl h"
            }

            locked {
              bind "Ctrl g" {
                SwitchToMode "Normal"
              }
            }

            resize {
              bind "h" "Left" {
                Resize "Increase Left"
              }
              bind "j" "Down" {
                Resize "Increase Down"
              }
              bind "k" "Up" {
                Resize "Increase Up"
              }
              bind "l" "Right" {
                Resize "Increase Right"
              }
              bind "H" {
                Resize "Decrease Left"
              }
              bind "J" {
                Resize "Decrease Down"
              }
              bind "K" {
                Resize "Decrease Up"
              }
              bind "L" {
                Resize "Decrease Right"
              }
              bind "=" "+" {
                Resize "Increase"
              }
              bind "-" {
                Resize "Decrease"
              }
            }

            pane {
              bind "n" {
                NewPane
                SwitchToMode "Locked"
              }
              bind "d" {
                NewPane "Down"
                SwitchToMode "Locked"
              }
              bind "x" {
                CloseFocus
                SwitchToMode "Locked"
              }
              bind "z" {
                ToggleFocusFullscreen
                SwitchToMode "Locked"
              }
              bind "f" {
                TogglePaneFrames
                SwitchToMode "Locked"
              }
              bind "w" {
                ToggleFloatingPanes
                SwitchToMode "Locked"
              }
              bind "e" {
                TogglePaneEmbedOrFloating
                SwitchToMode "Locked"
              }
              bind "r" {
                SwitchToMode "RenamePane"
                PaneNameInput 0
              }
            }

            tab {
              bind "r" {
                SwitchToMode "RenameTab"
                TabNameInput 0
              }
              bind "h" "Left" "Up" "k" {
                GoToPreviousTab
                SwitchToMode "Locked"
              }
              bind "l" "Right" "Down" "j" {
                GoToNextTab
                SwitchToMode "Locked"
              }
              bind "n" {
                NewTab
                SwitchToMode "Locked"
              }
              bind "x" {
                CloseTab
                SwitchToMode "Locked"
              }
              bind "s" {
                ToggleActiveSyncTab
                SwitchToMode "Locked"
              }
              bind "b" {
                BreakPane
                SwitchToMode "Locked"
              }
              bind "]" {
                BreakPaneRight
                SwitchToMode "Locked"
              }
              bind "[" {
                BreakPaneLeft
                SwitchToMode "Locked"
              }
              bind "1" {
                GoToTab 1
                SwitchToMode "Locked"
              }
              bind "2" {
                GoToTab 2
                SwitchToMode "Locked"
              }
              bind "3" {
                GoToTab 3
                SwitchToMode "Locked"
              }
              bind "4" {
                GoToTab 4
                SwitchToMode "Locked"
              }
              bind "5" {
                GoToTab 5
                SwitchToMode "Locked"
              }
              bind "6" {
                GoToTab 6
                SwitchToMode "Locked"
              }
              bind "7" {
                GoToTab 7
                SwitchToMode "Locked"
              }
              bind "8" {
                GoToTab 8
                SwitchToMode "Locked"
              }
              bind "9" {
                GoToTab 9
                SwitchToMode "Locked"
              }
              bind "a" {
                ToggleTab
                SwitchToMode "Locked"
              }
            }

            scroll {
              bind "e" {
                EditScrollback
                SwitchToMode "Locked"
              }
              bind "s" {
                SwitchToMode "EnterSearch"
                SearchInput
              }
              bind "G" {
                ScrollToBottom
                SwitchToMode "Locked"
              }
              bind "j" "Down" {
                ScrollDown
              }
              bind "k" "Up" {
                ScrollUp
              }
              bind "Ctrl f" "PageDown" "Right" "l" {
                PageScrollDown
              }
              bind "Ctrl b" "PageUp" "Left" "h" {
                PageScrollUp
              }
              bind "d" {
                HalfPageScrollDown
              }
              bind "u" {
                HalfPageScrollUp
              }
            }

            search {
              bind "j" "Down" {
                ScrollDown
              }
              bind "k" "Up" {
                ScrollUp
              }
              bind "Ctrl f" "PageDown" "Right" "l" {
                PageScrollDown
              }
              bind "Ctrl b" "PageUp" "Left" "h" {
                PageScrollUp
              }
              bind "d" {
                HalfPageScrollDown
              }
              bind "u" {
                HalfPageScrollUp
              }
              bind "n" {
                Search "down"
              }
              bind "p" {
                Search "up"
              }
              bind "c" {
                SearchToggleOption "CaseSensitivity"
              }
              bind "w" {
                SearchToggleOption "Wrap"
              }
              bind "o" {
                SearchToggleOption "WholeWord"
              }
            }

            entersearch {
              bind "Esc" {
                SwitchToMode "Scroll"
              }
              bind "Enter" {
                SwitchToMode "Search"
              }
            }

            renametab {
              bind "Esc" {
                UndoRenameTab
                SwitchToMode "Tab"
              }
            }

            renamepane {
              bind "Esc" {
                UndoRenamePane
                SwitchToMode "Pane"
              }
            }

            session {
              bind "d" {
                Detach
              }
              bind "w" {
                LaunchOrFocusPlugin "zellij:session-manager" {
                  floating true
                  move_to_focused_tab true
                };
                SwitchToMode "Locked"
              }
            }

            shared_except "locked" {
              bind "Ctrl g" {
                SwitchToMode "Locked"
              }
              bind "Alt n" {
                NewPane
              }
              bind "Alt h" "Alt Left" {
                MoveFocusOrTab "Left"
              }
              bind "Alt l" "Alt Right" {
                MoveFocusOrTab "Right"
              }
              bind "Alt j" "Alt Down" {
                MoveFocus "Down"
              }
              bind "Alt k" "Alt Up" {
                MoveFocus "Up"
              }
              bind "Alt =" "Alt +" {
                Resize "Increase"
              }
              bind "Alt -" {
                Resize "Decrease"
              }
              bind "Alt [" {
                PreviousSwapLayout
              }
              bind "Alt ]" {
                NextSwapLayout
              }
            }

            shared_except "normal" "locked" {
              bind "Enter" "Esc" {
                SwitchToMode "Locked"
              }
            }

            shared_except "pane" "locked" {
              bind "p" {
                SwitchToMode "Pane"
              }
            }

            shared_except "resize" "locked" {
              bind "r" {
                SwitchToMode "Resize"
              }
            }

            shared_except "search" "locked" {
              bind "/" {
                SwitchToMode "Search"
              }
            }

            shared_except "scroll" "locked" {
              bind "l" {
                SwitchToMode "Scroll"
              }
            }

            shared_except "session" "locked" {
              bind "x" {
                SwitchToMode "Session"
              }
            }

            shared_except "tab" "locked" {
              bind "t" {
                SwitchToMode "Tab"
              }
            }

            shared {
              bind "Alt h" "Alt Left" {
                MoveFocus "Left"
                SwitchToMode "Locked"
              }
              bind "Alt l" "Alt Right" {
                MoveFocus "Right"
                SwitchToMode "Locked"
              }
              bind "Alt j" "Alt Down" {
                MoveFocus "Down"
                SwitchToMode "Locked"
              }
              bind "Alt k" "Alt Up" {
                MoveFocus "Up"
                SwitchToMode "Locked"
              }
              bind "Alt p" {
                SwitchFocus
                SwitchToMode "Locked"
              }
              bind "Alt g" {
                Run "lazygit" {
                  floating true
                  x "10%"
                  y "10%"
                  width "80%"
                  height "80%"
                  close_on_exit true
                }
              }
              bind "Alt G" {
                Run "gh-dash" {
                  floating true
                  close_on_exit true
                  x "5%"
                  y "5%"
                  width "90%"
                  height "90%"
                }
              }
              bind "Alt v" {
                Run "nvim"
              }
              bind "Alt l" {
                Run "bash" "-c" "zellij action override-layout ~/.config/zellij/layouts/$(ls ~/.config/zellij/layouts/*.kdl | xargs -I{} basename {} .kdl | fzf)" {
                  floating true
                  close_on_exit true
                }
              }
            }
          }

          plugins {
            tab-bar {
              path "tab-bar"
            }
            status-bar {
              path "status-bar"
            }
            strider {
              path "strider"
            }
            compact-bar {
              path "compact-bar"
            }
          }

          default_layout "welcome"
          default_mode "locked"
          on_force_close "detach"
          pane_frames false
        '';
      };
    };
  };
}
