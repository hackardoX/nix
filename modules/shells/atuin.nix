{
  config,
  lib,
  ...
}:
{
  flake.modules.homeManager.shell = {
    programs.atuin = {
      enable = true;
      daemon.enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };

  flake.modules.homeManager.hackardo =
    hmArgs:
    lib.mkIf hmArgs.config.programs.atuin.enable {
      sops.secrets."shell/atuin_key" = {
        path = "${hmArgs.config.home.homeDirectory}/.secrets/.atuin_key";
      };
      sops.secrets."ai/lumo_api_key" = {
        path = "${hmArgs.config.home.homeDirectory}/.secrets/.lumo_key";
      };
      sops.templates."atuin-config" = {
        content = ''
          dialect = "uk"
          enter_accept = true
          filter_mode = "workspace"
          inline_height = 12
          keymap_mode = "auto"
          style = "auto"
          sync_frequency = "15m"
          update_check = false
          workspaces = true
          key_path = "${hmArgs.config.sops.secrets."shell/atuin_key".path}"

          [ai]
          enabled = true
          endpoint = "${config.flake.meta.aiProviders.lumo.endpoint}"
          model = "lumo-max"
          endpoint_protocol = "oss"
          api_token = "${hmArgs.config.sops.placeholder."ai/lumo_api_key"}"

          [daemon]
          enabled = true
          systemd_socket = ${if hmArgs.config.systemd.user.enable then "true" else "false"}
          socket_path = "${hmArgs.config.xdg.dataHome}/atuin/daemon.sock"
        '';
      };

      xdg.configFile."atuin/config.toml".source = lib.mkForce (
        hmArgs.config.lib.file.mkOutOfStoreSymlink hmArgs.config.sops.templates."atuin-config".path
      );
    };
}
