{ config, ... }:
{
  flake.modules.homeManager.base = hmArgs: {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = config.flake.meta.users.${hmArgs.config.home.username}.git.name;
          email = config.flake.meta.users.${hmArgs.config.home.username}.git.email;
        };
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
