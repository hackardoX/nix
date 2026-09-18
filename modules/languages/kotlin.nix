{ lib, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        kotlin-language-server
        ktlint
      ];

      lsp.servers.kotlin_language_server.enable = true;

      plugins.conform-nvim.settings.formatters_by_ft.kotlin = [ "ktlint" ];
    };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      programs.opencode = {
        extraPackages = with pkgs; [
          kotlin-language-server
        ];
        settings.lsp.kotlin-language-server = {
          command = [
            (lib.getExe pkgs.kotlin-language-server)
          ];
          extensions = [
            ".kt"
            ".kts"
          ];
          rootMarkers = [
            "build.gradle"
            "build.gradle.kts"
            "settings.gradle"
            "settings.gradle.kts"
            "pom.xml"
          ];
        };
      };
    };
}
