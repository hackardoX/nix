{
  pkgs,
  config,
  user,
  ...
}:
[
  { path = "/Applications/Safari.app/"; }
  { path = "/System/Applications/Mail.app/"; }
  { path = "/System/Applications/Calendar.app/"; }
  { path = "/System/Applications/System Settings.app/"; }
  { path = "${pkgs.spotify}/Applications/Spotify.app"; }
  { path = "${pkgs.whatsapp}/Applications/Spotify.app"; }
  { path = "${pkgs.warp-terminal}/Applications/Warp.app/"; }
  {
    path = "${config.users.users.${user}.home}/.local/share/";
    section = "others";
    options = "--sort name --view grid --display folder";
  }
  {
    path = "${config.users.users.${user}.home}/.local/share/downloads";
    section = "others";
    options = "--sort name --view grid --display stack";
  }
]
