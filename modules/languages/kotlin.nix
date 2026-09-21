{ lib, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackagesAfter = [ pkgs.ktlint ];

      lsp.servers.kotlin_language_server = {
        enable = true;
        packageFallback = true;
        config.root_markers = [
          "settings.gradle"
          "settings.gradle.kts"
          "build.xml"
          "pom.xml"
          "build.gradle"
          "build.gradle.kts"
          "BUILD.bazel"
          "BUILD"
          "WORKSPACE"
          "WORKSPACE.bazel"
          "MODULE.bazel"
        ];
      };

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
            "BUILD.bazel"
            "BUILD"
            "WORKSPACE"
            "WORKSPACE.bazel"
            "MODULE.bazel"
          ];
        };
      };
    };
}
