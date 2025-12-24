{
  flake.modules.homeManager.base =
    { osConfig, ... }:
    {
      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          add_newline = false;
          aws = {
            format = "[$symbol(profile: \"$profile\" )(\(region: $region\) )]($style)";
            disabled = false;
            style = "bold blue";
            symbol = " ";
          };
          character = {
            vicmd_symbol = "[←](bold green)";
            success_symbol = "[➜](bold green)";
            error_symbol = "[✗](bold red)";
          };
          command_timeout = 1000;
          directory.substitutions."~/tests/starship-custom" = "work-project";
          docker_context.disabled = true;
          format = "$directory$character";
          git_branch.format = "[$symbol$branch(:$remote_branch)]($style)";
          golang.format = "[ ](bold cyan)";
          kubernetes = {
            symbol = "☸ ";
            disabled = true;
            detect_files = [ "Dockerfile" ];
            format = "[$symbol$context( \($namespace\))]($style) ";
            contexts = [
              {
                style = "green";
                context_alias = osConfig.system.primaryUser;
                symbol = " ";
              }
            ];
          };
          right_format = "$all";
          nix_shell = {
            impure_msg = "";
          };
        };
      };
    };
}
