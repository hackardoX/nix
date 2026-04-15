{
  flake.modules.homeManager.shell = {
    xdg.configFile."zellij/layouts/git.kdl".text = ''
      layout {
        pane size=1 borderless=true {
          plugin location="zellij:tab-bar"
        }
        pane split_direction="vertical" {
          pane {
            command "lazygit"
            size "60%"
          }
          pane split_direction="horizontal" {
            pane { }
            pane {
              command "gh-dash"
            }
          }
        }
        pane size=1 borderless=true {
          plugin location="zellij:status-bar"
        }
      }
    '';
  };
}
