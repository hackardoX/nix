{
  flake.modules.homeManager.shell = {
    xdg.configFile."zellij/layouts/development.kdl".text = ''
      layout {
        pane size=1 borderless=true {
          plugin location="zellij:tab-bar"
        }
        pane split_direction="vertical" {
          pane {
            command "nvim"
            size "70%"
          }
          pane split_direction="horizontal" {
            pane { }
          }
        }
        pane size=1 borderless=true {
          plugin location="zellij:status-bar"
        }
      }
    '';
  };
}
