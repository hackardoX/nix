{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.zellij;
in
{
  options.${namespace}.programs.terminal.tools.zellij = {
    enable = lib.mkEnableOption "zellij";
  };

  config = mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        ui = {
          pane_frames = {
            hide_session_name = false;
          };
        };

        default_mode = "locked";
        show_startup_tips = false;
        "keybinds clear-defaults=true" = {
          normal = {
            "unbind \"Ctrl p\"" = [ ];
            "unbind \"Ctrl o\"" = [ ];
            "unbind \"Ctrl q\"" = [ ];
            "unbind \"Ctrl h\"" = [ ];
          };

          locked = {
            "bind \"Ctrl g\"" = {
              SwitchToMode = "Normal";
            };
          };

          resize = {
            "bind \"Ctrl n\"" = {
              SwitchToMode = "Normal";
            };
            "bind \"h\" \"Left\"" = {
              Resize = "Increase Left";
            };
            "bind \"j\" \"Down\"" = {
              Resize = "Increase Down";
            };
            "bind \"k\" \"Up\"" = {
              Resize = "Increase Up";
            };
            "bind \"l\" \"Right\"" = {
              Resize = "Increase Right";
            };
            "bind \"H\"" = {
              Resize = "Decrease Left";
            };
            "bind \"J\"" = {
              Resize = "Decrease Down";
            };
            "bind \"K\"" = {
              Resize = "Decrease Up";
            };
            "bind \"L\"" = {
              Resize = "Decrease Right";
            };
            "bind \"=\" \"+\"" = {
              Resize = "Increase";
            };
            "bind \"-\"" = {
              Resize = "Decrease";
            };
          };

          pane = {
            "bind \"Ctrl a\"" = {
              SwitchToMode = "Normal";
            };
            "bind \"h\" \"Left\"" = {
              MoveFocus = "Left";
              SwitchToMode = "Normal";
            };
            "bind \"l\" \"Right\"" = {
              MoveFocus = "Right";
              SwitchToMode = "Normal";
            };
            "bind \"j\" \"Down\"" = {
              MoveFocus = "Down";
              SwitchToMode = "Normal";
            };
            "bind \"k\" \"Up\"" = {
              MoveFocus = "Up";
              SwitchToMode = "Normal";
            };
            "bind \"p\"" = {
              SwitchFocus = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"n\"" = {
              NewPane = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"d\"" = {
              NewPane = "Down";
              SwitchToMode = "Normal";
            };
            "bind \"x\"" = {
              CloseFocus = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"z\"" = {
              ToggleFocusFullscreen = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"f\"" = {
              TogglePaneFrames = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"w\"" = {
              ToggleFloatingPanes = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"e\"" = {
              TogglePaneEmbedOrFloating = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"r\"" = {
              SwitchToMode = "RenamePane";
              PaneNameInput = 0;
            };
          };

          tab = {
            "bind \"Ctrl t\"" = {
              SwitchToMode = "Normal";
            };
            "bind \"r\"" = {
              SwitchToMode = "RenameTab";
              TabNameInput = 0;
            };
            "bind \"h\" \"Left\" \"Up\" \"k\"" = {
              GoToPreviousTab = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"l\" \"Right\" \"Down\" \"j\"" = {
              GoToNextTab = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"n\"" = {
              NewTab = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"x\"" = {
              CloseTab = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"s\"" = {
              ToggleActiveSyncTab = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"b\"" = {
              BreakPane = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"]\"" = {
              BreakPaneRight = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"[\"" = {
              BreakPaneLeft = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"1\"" = {
              GoToTab = 1;
              SwitchToMode = "Normal";
            };
            "bind \"2\"" = {
              GoToTab = 2;
              SwitchToMode = "Normal";
            };
            "bind \"3\"" = {
              GoToTab = 3;
              SwitchToMode = "Normal";
            };
            "bind \"4\"" = {
              GoToTab = 4;
              SwitchToMode = "Normal";
            };
            "bind \"5\"" = {
              GoToTab = 5;
              SwitchToMode = "Normal";
            };
            "bind \"6\"" = {
              GoToTab = 6;
              SwitchToMode = "Normal";
            };
            "bind \"7\"" = {
              GoToTab = 7;
              SwitchToMode = "Normal";
            };
            "bind \"8\"" = {
              GoToTab = 8;
              SwitchToMode = "Normal";
            };
            "bind \"9\"" = {
              GoToTab = 9;
              SwitchToMode = "Normal";
            };
            "bind \"a\"" = {
              ToggleTab = [ ];
              SwitchToMode = "Normal";
            };
          };

          scroll = {
            "bind \"Ctrl s\"" = {
              SwitchToMode = "Normal";
            };
            "bind \"e\"" = {
              EditScrollback = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"s\"" = {
              SwitchToMode = "EnterSearch";
              SearchInput = [ ];
            };
            "bind \"G\"" = {
              ScrollToBottom = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"j\"" = {
              ScrollDown = [ ];
            };
            "bind \"Down\"" = {
              ScrollDown = [ ];
            };
            "bind \"k\"" = {
              ScrollUp = [ ];
            };
            "bind \"Up\"" = {
              ScrollUp = [ ];
            };
            "bind \"Ctrl f\"" = {
              PageScrollDown = [ ];
            };
            "bind \"PageDown\"" = {
              PageScrollDown = [ ];
            };
            "bind \"Right\"" = {
              PageScrollDown = [ ];
            };
            "bind \"l\"" = {
              PageScrollDown = [ ];
            };
            "bind \"Ctrl b\"" = {
              PageScrollUp = [ ];
            };
            "bind \"PageUp\"" = {
              PageScrollUp = [ ];
            };
            "bind \"Left\"" = {
              PageScrollUp = [ ];
            };
            "bind \"h\"" = {
              PageScrollUp = [ ];
            };
            "bind \"d\"" = {
              HalfPageScrollDown = [ ];
            };
            "bind \"u\"" = {
              HalfPageScrollUp = [ ];
            };
            # "bind \"Alt c\"" = { Copy = []; };
          };

          search = {
            "bind \"Ctrl /\"" = {
              SwitchToMode = "Normal";
            };
            "bind \"j\"" = {
              ScrollDown = [ ];
            };
            "bind \"Down\"" = {
              ScrollDown = [ ];
            };
            "bind \"k\"" = {
              ScrollUp = [ ];
            };
            "bind \"Up\"" = {
              ScrollUp = [ ];
            };
            "bind \"Ctrl f\"" = {
              PageScrollDown = [ ];
            };
            "bind \"PageDown\"" = {
              PageScrollDown = [ ];
            };
            "bind \"Right\"" = {
              PageScrollDown = [ ];
            };
            "bind \"l\"" = {
              PageScrollDown = [ ];
            };
            "bind \"Ctrl b\"" = {
              PageScrollUp = [ ];
            };
            "bind \"PageUp\"" = {
              PageScrollUp = [ ];
            };
            "bind \"Left\"" = {
              PageScrollUp = [ ];
            };
            "bind \"h\"" = {
              PageScrollUp = [ ];
            };
            "bind \"d\"" = {
              HalfPageScrollDown = [ ];
            };
            "bind \"u\"" = {
              HalfPageScrollUp = [ ];
            };
            "bind \"n\"" = {
              Search = "down";
            };
            "bind \"p\"" = {
              Search = "up";
            };
            "bind \"c\"" = {
              SearchToggleOption = "CaseSensitivity";
            };
            "bind \"w\"" = {
              SearchToggleOption = "Wrap";
            };
            "bind \"o\"" = {
              SearchToggleOption = "WholeWord";
            };
          };

          entersearch = {
            "bind \"Ctrl s\"" = {
              SwitchToMode = "Scroll";
            };
            "bind \"Esc\"" = {
              SwitchToMode = "Scroll";
            };
            "bind \"Enter\"" = {
              SwitchToMode = "Search";
            };
          };

          renametab = {
            "bind \"Ctrl s\"" = {
              SwitchToMode = "Normal";
            };
            "bind \"Esc\"" = {
              UndoRenameTab = [ ];
              SwitchToMode = "Tab";
            };
          };

          renamepane = {
            "bind \"Ctrl c\"" = {
              SwitchToMode = "Normal";
            };
            "bind \"Esc\"" = {
              UndoRenamePane = [ ];
              SwitchToMode = "Pane";
            };
          };

          session = {
            "bind \"Ctrl x\"" = {
              SwitchToMode = "Normal";
            };
            "bind \"d\"" = {
              Detach = [ ];
            };
            "bind \"w\"" = {
              "LaunchOrFocusPlugin \"zellij:session-manager\"" = {
                floating = true;
                move_to_focused_tab = true;
              };
              SwitchToMode = "Normal";
            };
          };

          tmux = {
            "bind \"[\"" = {
              SwitchToMode = "Scroll";
            };
            "bind \"Ctrl b\"" = {
              Write = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"\\\"\"" = {
              NewPane = "Down";
              SwitchToMode = "Normal";
            };
            "bind \"%\"" = {
              NewPane = "Right";
              SwitchToMode = "Normal";
            };
            "bind \"z\"" = {
              ToggleFocusFullscreen = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"c\"" = {
              NewTab = [ ];
              SwitchToMode = "Normal";
            };
            "bind \",\"" = {
              SwitchToMode = "RenameTab";
            };
            "bind \"p\"" = {
              GoToPreviousTab = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"n\"" = {
              GoToNextTab = [ ];
              SwitchToMode = "Normal";
            };
            "bind \"Left\"" = {
              MoveFocus = "Left";
              SwitchToMode = "Normal";
            };
            "bind \"Right\"" = {
              MoveFocus = "Right";
              SwitchToMode = "Normal";
            };
            "bind \"Down\"" = {
              MoveFocus = "Down";
              SwitchToMode = "Normal";
            };
            "bind \"Up\"" = {
              MoveFocus = "Up";
              SwitchToMode = "Normal";
            };
            "bind \"h\"" = {
              MoveFocus = "Left";
              SwitchToMode = "Normal";
            };
            "bind \"l\"" = {
              MoveFocus = "Right";
              SwitchToMode = "Normal";
            };
            "bind \"j\"" = {
              MoveFocus = "Down";
              SwitchToMode = "Normal";
            };
            "bind \"k\"" = {
              MoveFocus = "Up";
              SwitchToMode = "Normal";
            };
            "bind \"o\"" = {
              FocusNextPane = [ ];
            };
            "bind \"d\"" = {
              Detach = [ ];
            };
            "bind \"Space\"" = {
              NextSwapLayout = [ ];
            };
            "bind \"x\"" = {
              CloseFocus = [ ];
              SwitchToMode = "Normal";
            };
          };

          "shared_except \"locked\"" = {
            "bind \"Ctrl g\"" = {
              SwitchToMode = "Locked";
            };
            "bind \"Alt n\"" = {
              NewPane = [ ];
            };
            "bind \"Alt h\" \"Alt Left\"" = {
              MoveFocusOrTab = "Left";
            };
            "bind \"Alt l\" \"Alt Right\"" = {
              MoveFocusOrTab = "Right";
            };
            "bind \"Alt j\" \"Alt Down\"" = {
              MoveFocus = "Down";
            };
            "bind \"Alt k\" \"Alt Up\"" = {
              MoveFocus = "Up";
            };
            "bind \"Alt =\" \"Alt +\"" = {
              Resize = "Increase";
            };
            "bind \"Alt -\"" = {
              Resize = "Decrease";
            };
            "bind \"Alt [\"" = {
              PreviousSwapLayout = [ ];
            };
            "bind \"Alt ]\"" = {
              NextSwapLayout = [ ];
            };
          };
          "shared_except \"normal\" \"locked\"" = {
            "bind \"Enter\" \"Esc\"" = {
              SwitchToMode = "Normal";
            };
          };
          "shared_except \"pane\" \"locked\"" = {
            "bind \"Ctrl a\"" = {
              SwitchToMode = "Pane";
            };
          };
          "shared_except \"resize\" \"locked\"" = {
            "bind \"Ctrl n\"" = {
              SwitchToMode = "Resize";
            };
          };
          "shared_except \"scroll\" \"locked\"" = {
            "bind \"Ctrl s\"" = {
              SwitchToMode = "Scroll";
            };
          };
          "shared_except \"session\" \"locked\"" = {
            "bind \"Ctrl x\"" = {
              SwitchToMode = "Session";
            };
          };
          "shared_except \"tab\" \"locked\"" = {
            "bind \"Ctrl t\"" = {
              SwitchToMode = "Tab";
            };
          };
          "shared_except \"renametab\" \"locked\"" = {
            "bind \"Alt r\"" = {
              SwitchToMode = "RenameTab";
            };
          };
          "shared_except \"tmux\" \"locked\"" = {
            "bind \"Ctrl b\"" = {
              SwitchToMode = "Tmux";
            };
          };
        };

        plugins = {
          tab-bar = {
            path = "tab-bar";
          };
          status-bar = {
            path = "status-bar";
          };
          strider = {
            path = "strider";
          };
          compact-bar = {
            path = "compact-bar";
          };
        };

        on_force_close = "detach";
        simplified_ui = true;
        pane_frames = false;
      };
    };
  };
}
