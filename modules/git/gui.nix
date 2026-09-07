{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        delta
        diffnav
      ];

      programs = {
        lazygit = {
          enable = true;
          settings.git.pagers = [
            { useExternalDiffGitConfig = true; }
            { pager = "delta --dark --paging=never"; }
          ];
        };
      };
    };

  flake.modules.homeManager.github = hmArgs: {
    programs = {
      gh = {
        enable = true;
        settings.git_protocol = "ssh";
      };

      gh-dash = {
        enable = true;
        settings = {
          prSections = [
            {
              title = "My PRs";
              filters = "is:open author:@me";
            }
            {
              title = "To Review";
              filters = "is:open review-requested:@me";
            }
            {
              title = "Involved";
              filters = "is:open involves:@me -author:@me";
            }
          ];
          issueSections = [
            {
              title = "My Issues";
              filters = "is:open author:@me";
            }
            {
              title = "Assigned";
              filters = "is:open assignee:@me";
            }
            {
              title = "Involved";
              filters = "is:open involves:@me -author:@me";
            }
          ];
          pager.diff = "diffnav";
        };
      };
    };

    sops.secrets."github/token" = {
      path = "${hmArgs.config.home.homeDirectory}/.secrets/.github_token";
    };

    home.sessionVariables =
      let
        tokenCmd = "$(cat ${hmArgs.config.sops.secrets."github/token".path})";
      in
      {
        GH_TOKEN = tokenCmd;
        GITHUB_TOKEN = tokenCmd;
      };
  };
}
