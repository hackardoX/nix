{ lib, ... }: {
  perSystem.treefmt.programs.stylua.enable = true;

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    let
      runtimeFiletypes = [
        "gd"
        "gdscript3"
        "gotmpl"
        "markdown.mdx"
        "qmljs"
        "teal"
        "yaml.docker-compose"
        "yaml.gitlab"
        "yaml.helm-values"
      ];

      mkRuntimeFiletype = filetype: {
        name = "ftplugin/${filetype}.vim";
        value.source = builtins.toFile "${filetype}.vim" ''
          " Register filetypes advertised by nvim-lspconfig so vim.lsp health
          " does not flag them as unknown. Detection still comes from filetype rules.
        '';
      };
    in
    {
      extraFiles = lib.listToAttrs (map mkRuntimeFiletype runtimeFiletypes);
      extraPackages = with pkgs; [
        lua
        stylua
      ];

      lsp.servers.lua_ls = {
        enable = true;
        config.settings.Lua.diagnostics.globals = [ "vim" ];
      };

      plugins = {
        conform-nvim.settings = {
          formatters_by_ft.lua = [ "stylua" ];
          formatters.stylua.command = lib.getExe pkgs.stylua;
        };
      };
    };
}
