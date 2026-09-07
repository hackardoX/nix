{ lib, ... }: {
  flake.modules.homeManager.shell = hmArgs: {
    programs = {
      atuin = {
        enableBashIntegration = true;
        enableFishIntegration = true;
        enable = true;
        enableZshIntegration = true;
        settings = {
          dialect = "uk";
          enter_accept = true;
          filter_mode = "workspace";
          inline_height = 12;
          keymap_mode = "auto";
          style = "auto";
          sync_frequency = "15m";
          update_check = false;
          workspaces = true;
        };
      };
    };
  };

  flake.modules.homeManager.hackardo =
    hmArgs:
    lib.mkIf hmArgs.config.programs.atuin.enable {
      programs = {
        atuin = {
          settings = {
            key_path = hmArgs.config.sops.secrets."shell/atuin_key".path;
          };
        };
      };
      sops.secrets."shell/atuin_key" = {
        path = "${hmArgs.config.home.homeDirectory}/.secrets/.atuin_key";
      };
    };
}
