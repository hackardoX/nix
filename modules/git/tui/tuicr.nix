{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    { pkgs, config, ... }:
    let
      inherit (config.catppuccin) flavor;
    in
    {
      home.packages = with pkgs; [
        glab
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.tuicr
      ];

      xdg.configFile."tuicr/config.toml".text = ''
        theme = "catppuccin-${flavor}"
        diff_view = "side-by-side"
        editor = "nvim"
        mouse = true
        transparent_background = true
        cursor_line = true
        relative_line_numbers = true
        scroll_offset = 5
        show_pr_comments = true
        no_update_check = true

        comment_types = [
          { id = "issue",      definition = "problems to fix",                          color = "red" },
          { id = "suggestion", definition = "possible improvements",                    color = "yellow" },
          { id = "question",   definition = "ask for clarification",                    color = "blue" },
          { id = "nit",        label = "nitpick", definition = "small optional tweaks", color = "#d19a66" },
          { id = "praise",     definition = "positive feedback",                        color = "green" },
        ]

        [forge]
        comment_type_prefix = true

        [export]
        intro = "I reviewed your code and have the following comments. Please address them."
        scope_line = true
        pr_metadata = true
        comments_header = "## Local tuicr Comments"
        legend = true
      '';
    };
}
