# Original source: https://gist.github.com/antifuchs/10138c4d838a63c0a05e725ccd7bccdd
_:
{
  pkgs,
  config,
  system,
  user,
  lib,
  ...
}:
let
  normalize = path: if lib.hasSuffix ".app" path then path + "/" else path;
  entryURI =
    path:
    "file://"
    + (builtins.replaceStrings
      [
        " "
        "!"
        "\""
        "#"
        "$"
        "%"
        "&"
        "'"
        "("
        ")"
      ]
      [
        "%20"
        "%21"
        "%22"
        "%23"
        "%24"
        "%25"
        "%26"
        "%27"
        "%28"
        "%29"
      ]
      (normalize path)
    );
  apps = builtins.import ./applications.nix { inherit pkgs config user; };
  wantURIs = lib.concatMapStrings (entry: "${entryURI entry.path}\n") apps;
  createEntries = lib.concatMapStrings
    (entry: "${pkgs.dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}\n")
    apps;
in
{
  system.activationScripts.postUserActivation.text = ''
    echo >&2 "Setting up the Dock..."
    haveURIs="$(${pkgs.dockutil}/bin/dockutil --list | ${pkgs.coreutils}/bin/cut -f2)"
    if ! diff -wu <(echo -n "$haveURIs") <(echo -n '${wantURIs}') >&2 ; then
      echo >&2 "Resetting Dock."
      ${pkgs.dockutil}/bin/dockutil --no-restart --remove all
      ${createEntries}
      killall Dock
    else
      echo >&2 "Dock setup complete."
    fi
  '';
}
