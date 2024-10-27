{
  pkgs,
  config,
  user,
}:
[
  {
    path = "/Applications/Safari.app/";
    section = "apps";
    options = "";
  }
  {
    path = "/System/Applications/Mail.app/";
    section = "apps";
    options = "";
  }
  {
    path = "/System/Applications/Calendar.app/";
    section = "apps";
    options = "";
  }
  {
    path = "/System/Applications/System Settings.app/";
    section = "apps";
    options = "";
  }
  {
    path = "${pkgs.spotify}/Applications/Spotify.app";
    section = "apps";
    options = "";
  }
  {
    path = "${pkgs.warp-terminal}/Applications/Warp.app/";
    section = "apps";
    options = "";
  }
  {
    path = "${config.users.users.${user}.home}/";
    section = "others";
    options = "--sort name --view grid --display folder";
  }
  {
    path = "${config.users.users.${user}.home}/downloads";
    section = "others";
    options = "--sort name --view grid --display stack";
  }
]
