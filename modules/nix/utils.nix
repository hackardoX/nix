{ lib, ... }:
{
  flake.modules.homeManager.laptop =
    {
      config,
      pkgs,
      ...
    }:
    {
      programs.nh = {
        enable = true;
        package = pkgs.nh;
        clean = {
          enable = true;
          extraArgs = "--keep-since 1w --keep 2";
        };
        flake = "${config.home.homeDirectory}/Github/nix";
      };

      home.shellAliases = {
        # nix specific aliases
        bloat = "nix path-info -Sh /run/current-system";
        curgen = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
        gc-check = "nix-store --gc --print-roots | egrep -v \"^(/nix/var|/run/\w+-system|\{memory|/proc)\"";
        repair = "nix-store --verify --check-contents --repair";
        nixnuke = ''
          # Kill nix-daemon and nix processes first
          sudo pkill -9 -f "nix-(daemon|store|build)" || true

          # Find and kill all nixbld processes
          for pid in $(ps -axo pid,user | ${lib.getExe pkgs.gnugrep} -E '[_]?nixbld[0-9]+' | ${lib.getExe pkgs.gawk} '{print $1}'); do
            sudo kill -9 "$pid" 2>/dev/null || true
          done

          # Restart nix-daemon based on platform
          if [ "$(uname)" = "Darwin" ]; then
            sudo launchctl kickstart -k system/org.nixos.nix-daemon
          else
            sudo systemctl restart nix-daemon.service
          fi
        '';
        nixre = "nh ${if pkgs.stdenv.hostPlatform.isLinux then "os" else "darwin"} switch";
        hmvar-reload = ''__HM_ZSH_SESS_VARS_SOURCED=0 source "/etc/profiles/per-user/${config.home.username}/etc/profile.d/hm-session-vars.sh"'';
      };
    };
}
