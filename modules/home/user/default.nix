{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    mkDefault
    mkMerge
    getExe
    ;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.user;
in
{
  options = import (lib.snowfall.fs.get-file "modules/shared/user/default.nix") {
    inherit
      config
      lib
      pkgs
      namespace
      ;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "${namespace}.user.name must be set";
        }
        {
          assertion = cfg.home != null;
          message = "${namespace}.user.home must be set";
        }
      ];

      home = {
        file = {
          "Desktop/.keep".text = "";
          "Documents/.keep".text = "";
          "Downloads/.keep".text = "";
          "Music/.keep".text = "";
          "Pictures/.keep".text = "";
          "Videos/.keep".text = "";
        }
        // lib.optionalAttrs (cfg.icon != null) {
          ".face".source = cfg.icon;
          ".face.icon".source = cfg.icon;
          "Pictures/${cfg.icon.fileName or (builtins.baseNameOf cfg.icon)}".source = cfg.icon;
        };

        homeDirectory = mkDefault cfg.home;

        shellAliases = {
          # nix specific aliases
          cleanup = "sudo nix-collect-garbage --delete-older-than 3d && nix-collect-garbage -d";
          bloat = "nix path-info -Sh /run/current-system";
          curgen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
          gc-check = "nix-store --gc --print-roots | egrep -v \"^(/nix/var|/run/\w+-system|\{memory|/proc)\"";
          repair = "nix-store --verify --check-contents --repair";
          nixnuke = ''
            # Kill nix-daemon and nix processes first
            sudo pkill -9 -f "nix-(daemon|store|build)" || true

            # Find and kill all nixbld processes
            for pid in $(ps -axo pid,user | ${getExe pkgs.gnugrep} -E '[_]?nixbld[0-9]+' | ${getExe pkgs.gawk} '{print $1}'); do
              sudo kill -9 "$pid" 2>/dev/null || true
            done

            # Restart nix-daemon based on platform
            if [ "$(uname)" = "Darwin" ]; then
              sudo launchctl kickstart -k system/org.nixos.nix-daemon
            else
              sudo systemctl restart nix-daemon.service
            fi
          '';
          hmvar-reload = ''__HM_ZSH_SESS_VARS_SOURCED=0 source "/etc/profiles/per-user/${config.${namespace}.user.name}/etc/profile.d/hm-session-vars.sh"'';

          # File management
          wget = "${getExe pkgs.wget} -c ";

          # Navigation shortcuts
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
          "......" = "cd ../../../../..";
          myipv4 = "${getExe pkgs.curl} api.ipify.org";
          myipv6 = "${getExe pkgs.curl} api6.ipify.org";
        };

        username = mkDefault cfg.name;
      };

      programs.home-manager = enabled;

      programs.zsh.initContent = lib.mkIf config.${namespace}.programs.terminal.shell.zsh.enable ''
        function nix() {
          if [[ "$1" == "develop" ]]; then
            # Remove 'develop' from the arguments list
            shift
            # Execute 'nix develop' with the remaining arguments and append '-c pkgs.zsh'
            command nix develop "$@" -c ${lib.getExe pkgs.zsh}
          else
            # Execute any other 'nix' command normally
            command nix "$@"
          fi
        }
      '';
    }
  ]);
}
