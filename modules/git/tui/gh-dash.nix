{
  flake.modules.homeManager.github = {
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
  };
}
