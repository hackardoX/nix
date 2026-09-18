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

      lsp.servers.sourcekit = {
        enable = true;
        config = {
          filetypes = [
            "swift"
            "objc"
          ];
          root_dir = {
            markers = [
              "Package.swift"
              "compile_commands.json"
              ".git"
            ];
          };
        };
      };

      # conform's "swift" formatter shells out to `swift format` from the
      # same toolchain (/usr/bin/swift shim).
      plugins.conform-nvim.settings.formatters_by_ft.swift = [ "swift" ];
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
