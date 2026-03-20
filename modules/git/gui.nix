{
  flake.modules.homeManager.dev =
    hmArgs@{ pkgs, ... }:
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

        onepassword-secrets.secrets = {
          githubToken = {
            path = ".secrets/github_token";
            reference = "op://Development/GitHub Personal Access Token/token";
            group = if pkgs.stdenv.isDarwin then "staff" else "wheel";
          };
        };
      };

      home.sessionVariables =
        let
          tokenCmd = "$(cat ${hmArgs.config.programs.onepassword-secrets.secretPaths.githubToken})";
        in
        {
          GH_TOKEN = tokenCmd;
          GITHUB_TOKEN = tokenCmd;
        };
    };
}
