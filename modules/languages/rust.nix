{ lib, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackagesAfter = [
        pkgs.rustfmt
        pkgs.rustc
        pkgs.cargo
        pkgs.clippy
      ];

      lsp.servers.rust_analyzer = {
        enable = true;
        packageFallback = true;
        config.settings."rust-analyzer" = {
          check = {
            command = "clippy";
          };
          inlayHints = {
            typeHints.enable = true;
            chainingHints.enable = true;
            closingBraceHints.enable = true;
            parameterHints.enable = true;
          };
        };
      };

      plugins.conform-nvim.settings.formatters_by_ft.rust = [ "rustfmt" ];
    };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        rustc
        cargo
        rustfmt
        clippy
      ];

      programs.opencode = {
        extraPackages = with pkgs; [
          rust-analyzer
        ];
        settings.lsp.rust-analyzer = {
          command = [
            (lib.getExe pkgs.rust-analyzer)
          ];
          extensions = [ ".rs" ];
          rootMarkers = [
            "Cargo.toml"
            "rust-project.json"
          ];
        };
      };
    };
}
