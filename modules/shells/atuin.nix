{
  lib,
  ...
}:
{
  flake.modules.homeManager.shell = {
    programs.atuin = {
      enable = true;
      enableBashIntegration = true;
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

  flake.modules.homeManager.hackardo =
    hmArgs@{ pkgs, ... }:
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
          endpoint = "http://localhost:9999"
          endpoint_protocol = "oss"
          model = "lumo-max"

          [daemon]
          enabled = true
          autostart = true
        '';
      };

      xdg.configFile."atuin/config.toml".source = lib.mkForce (
        hmArgs.config.lib.file.mkOutOfStoreSymlink hmArgs.config.sops.templates."atuin-config".path
      );

      sops.templates."atuin-ai-server-config".content = ''
        port = 9999 
        endpoint = "https://lumo.proton.me/api/ai/v1"
        default_model = "lumo-max"

        [[models]]
        alias = "lumo-max"
        name = "Lumo Max"
        model = "lumo-max"
        api_key = "${hmArgs.config.sops.placeholder."ai/lumo_api_key"}"
      '';

      home.packages = [
        pkgs.beamPackages.erlang
        pkgs.beamPackages.elixir
        pkgs.gleam
      ];

      launchd.agents.atuin-ai-server =
        let
          atuinAiServerSrc = pkgs.fetchFromGitHub {
            owner = "atuinsh";
            repo = "atuin-ai-server";
            rev = "main";
            hash = "sha256-+Iqqd12yUHOSm29uHUeWs2Z9fnutH9fOoTLb9EdvPMY=";
          };
          beamEnv = pkgs.buildEnv {
            name = "atuin-ai-server-beam-env";
            paths = [
              pkgs.beamPackages.erlang
              pkgs.beamPackages.elixir
              pkgs.gleam
            ];
          };
          workDir = "${hmArgs.config.xdg.stateHome}/atuin-ai-server";
        in
        {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.bash}/bin/bash"
              "-c"
              ''
                set -e
                secret="${hmArgs.config.sops.templates."atuin-ai-server-config".path}"
                for i in $(seq 1 30); do [ -s "$secret" ] && break; sleep 1; done

                mkdir -p "${workDir}"
                rsync -a --delete "${atuinAiServerSrc}/" "${workDir}/"
                chmod -R u+w "${workDir}"
                cd "${workDir}"

                export PATH="${beamEnv}/bin:$PATH"
                export MIX_HOME="${workDir}/.mix"
                export HEX_HOME="${workDir}/.hex"
                export CHAT_CONFIG="$secret"

                mix local.hex --force --if-missing
                mix local.rebar --force --if-missing
                mix deps.get
                exec mix run --no-halt
              ''
            ];
            KeepAlive = true;
            RunAtLoad = true;
            StandardOutPath = "${hmArgs.config.xdg.stateHome}/atuin-ai-server.log";
            StandardErrorPath = "${hmArgs.config.xdg.stateHome}/atuin-ai-server.err.log";
          };
        };
    };
}
