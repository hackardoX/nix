_: {
  flake.modules.homeManager.git = hmArgs: {
    programs.git = {
      enable = true;
      settings = {
        branch.sort = "-committerdate";
        column.ui = "auto";
        commit.verbose = true;
        init.defaultBranch = "main";
        safe = {
          directory = [
            "${hmArgs.config.home.homeDirectory}"
            "/etc/nixos"
            "/etc/nix-darwin"
          ];
        };
        tag.sort = "taggerdate";
        "url \"ssh://git@\"" = {
          insteadOf = "https://";
        };
      };
    };
  };
}
