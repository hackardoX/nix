{ config, ... }:
{
  flake.modules.homeManager.base = hmArgs: {
    programs.git = {
      enable = true;
      settings = {
        user = {
          inherit (config.flake.meta.users.aaccardo) email name;
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
