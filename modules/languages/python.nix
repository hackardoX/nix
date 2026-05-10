{ lib, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        basedpyright
        ruff
      ];
      plugins = {
        conform-nvim.settings = {
          formatters_by_ft.python = [ "ruff_format" ];
          formatters.ruff_format.command = "${pkgs.ruff}/bin/ruff";
        };
        dap-python.enable = true;
        lsp.servers = {
          basedpyright.enable = true;
          ruff.enable = true;
        };
      };
    };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      programs.opencode = {
        extraPackages = with pkgs; [
          basedpyright
          ruff
        ];
        settings.lsp = {
          basedpyright = {
            command = [
              (lib.getExe' pkgs.basedpyright "basedpyright-langserver")
              "--stdio"
            ];
            extensions = [
              ".py"
              ".pyi"
              ".pyw"
            ];
          };

          ruff = {
            command = [
              (lib.getExe pkgs.ruff)
              "server"
            ];
            extensions = [
              ".py"
              ".pyi"
              ".pyw"
            ];
          };
        };
      };
    };
}
