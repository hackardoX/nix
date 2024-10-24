{
  pkgs,
  config,
  user,
}:
[
  {
    path = "/Applications/Safari.app/";
    display = "";
    options = "";
    section = "";
    type = "";
    view = "";
  }
  {
    path = "/System/Applications/Mail.app/";
    display = "";
    options = "";
    section = "";
    type = "";
    view = "";
  }
  {
    path = "/System/Applications/Calendar.app/";
    display = "";
    options = "";
    section = "";
    type = "";
    view = "";
  }
  {
    path = "/System/Applications/System Settings.app/";
    display = "";
    options = "";
    section = "";
    type = "";
    view = "";
  }
  {
    path = "${pkgs.spotify}/Applications/Spotify.app";
    display = "";
    options = "";
    section = "";
    type = "";
    view = "";
  }
  {
    path = "${pkgs.warp-terminal}/Applications/Warp.app/";
    display = "";
    options = "";
    section = "";
    type = "";
    view = "";
  }
  {
    path = "${config.users.users.${user}.home}/";
    display = "";
    type = "";
    view = "";
    section = "others";
    options = "--sort name --view grid --display folder";
  }
  {
    path = "${config.users.users.${user}.home}/downloads";
    display = "";
    type = "";
    view = "";
    section = "others";
    options = "--sort name --view grid --display stack";
  }
]
