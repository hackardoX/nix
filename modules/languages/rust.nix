{ lib, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        rust-analyzer
        rustc
        cargo
        rustfmt
        clippy
      ];

      lsp.servers.rust_analyzer = {
        enable = true;
        # rust-analyzer ships its own binary name `rust-analyzer`; nixvim's
        # autoInstall resolves it, pin the store path anyway for purity.
        config.cmd = [ (lib.getExe pkgs.rust-analyzer) ];
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
