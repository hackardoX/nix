{ lib, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      # Apple's Swift toolchain (Xcode or Command Line Tools) is used directly:
      # sourcekit-lsp must match the installed SDK, which Nix cannot provide.
      extraPackages = [
        (pkgs.writeShellScriptBin "sourcekit-lsp" ''
          exec $(/usr/bin/xcrun --find sourcekit-lsp) "$@"
        '')
      ];
      extraPackagesAfter = [ pkgs.swift-format ];

      lsp.servers.sourcekit = {
        enable = true;
        package = null;
        config = {
          filetypes = [
            "swift"
            "objc"
          ];
        };
      };

      # `swift_format` calls the swift-format binary directly; the `swift`
      # formatter would run `swift format`, which autoInstall resolves to
      # nixpkgs' swift wrapper (5.10.1) whose dispatch fails without a
      # companion swift-format on its PATH.
      plugins.conform-nvim.settings.formatters_by_ft.swift = [ "swift_format" ];
    };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      programs.opencode = {
        settings.lsp.sourcekit-lsp = {
          command = [
            "/usr/bin/xcrun"
            "sourcekit-lsp"
          ];
          extensions = [ ".swift" ];
          rootMarkers = [
            "Package.swift"
            "compile_commands.json"
          ];
        };
      };
    };
}
