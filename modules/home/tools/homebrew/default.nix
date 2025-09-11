{
  inputs,
  lib,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (inputs) home-manager;

  cfg = osConfig.${namespace}.tools.homebrew;
in
{
  config = mkIf cfg.enable {
    home.activation.homebrew-cleanup = home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PATH="/opt/homebrew/bin:$PATH"
      echo "Removing homebrew cache..."
      brew cleanup --prune=all
    '';
  };
}
