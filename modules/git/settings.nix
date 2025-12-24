{ config, ... }:
{
  flake.modules.homeManager.base = homeManagerArgs: {
    programs.git.settings = {
      user = {
        inherit (config.flake.meta.users.hackardo) email name;
      };
      branch.sort = "-committerdate";
      column.ui = "auto";
      commit.verbose = true;
      init.defaultBranch = "main";
      safe = {
        directory = [
          "${homeManagerArgs.config.home.homeDirectory}"
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
}
