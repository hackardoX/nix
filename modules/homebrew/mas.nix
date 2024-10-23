# These app IDs are from using the mas CLI app
# mas = mac app store
# https://github.com/mas-cli/mas
#
# $ nix shell nixpkgs#mas
# $ mas search <app name>
#
# If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
# you may receive an error message "Redownload Unavailable with This Apple ID".
# This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)
{
  "1password-safari" = 1569813296;
}
