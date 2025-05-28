{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkOpt;

  inherit (config.snowfallorg.user) name;

  home-directory =
    if name == null then
      null
    else if pkgs.stdenv.hostPlatform.isDarwin then
      "/Users/${name}"
    else
      "/home/${name}";
in
{
  ${namespace}.user = {
    enable = mkOpt types.bool false "Whether to configure the user account.";
    email = mkOpt types.str "andry93.mail@gmail.com" "The email of the user.";
    fullName = mkOpt types.str "Andrea Accardo" "The full name of the user.";
    home = mkOpt (types.nullOr types.str) home-directory "The user's home directory.";
    icon =
      mkOpt (types.nullOr types.package) pkgs.${namespace}.user-icon
        "The profile picture to use for the user.";
    name = mkOpt (types.nullOr types.str) name "The user account.";
  };
}
