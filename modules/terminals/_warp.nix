{ lib, ... }:
{
  flake.modules.darwin.base.homebrew.casks = [
    "warp"
  ];

  flake.modules.homeManager.base =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      targets.darwin.defaults = {
        dev.warp.Warp-Stable = {
          AddedSubshellCommands = ''[\\"nix develop\\"]'';
          AliasExpansionBannerSeen = "true";
          AliasExpansionEnabled = "true";
          AutocompleteSymbols = "false";
          Notifications = ''"{\\"mode\\":\\"Enabled\\",\\"is_long_running_enabled\\":true,\\"long_running_threshold\\":{\\"secs\\":30,\\"nanos\\":0},\\"is_password_prompt_enabled\\":true}"'';
          TelemetryEnabled = "false";
          UseSshTmuxWrapper = true;
        };
      };

      programs.zsh.initContent = lib.mkAfter ''
        # Auto-Warpify
        [[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Darwin" }}�'
      '';

      programs.bash.initExtra = lib.mkAfter ''
        # Auto-Warpify
        [[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "bash", "uname": "Darwin" }}ú'
      '';

      home = {
        file = lib.mkMerge [
          (
            let
              warpThemePkg = pkgs.fetchFromGitHub {
                owner = "catppuccin";
                repo = "warp";
                rev = "b6891cc339b3a1bb70a5c3063add4bdbd0455603";
                hash = "sha256-ypzSeSWT2XfdjfdeE/lLdiRgRmxewAqiWhGp6jjF7hE=";
              };

              themes = [
                "catppuccin_macchiato"
                "catppuccin_mocha"
                "catppuccin_frappe"
                "catppuccin_latte"
              ];

              makeThemeEntry = pathPrefix: theme: {
                name = "${pathPrefix}/${theme}.yaml";
                value.source = "${warpThemePkg.outPath}/themes/${theme}.yml";
              };
            in
            builtins.listToAttrs (
              builtins.concatLists (
                map (theme: [
                  (makeThemeEntry ".warp/themes" theme)
                  (makeThemeEntry ".local/share/warp-terminal/themes" theme)
                ]) themes
              )
            )
          )
        ];
      };
    };
}
