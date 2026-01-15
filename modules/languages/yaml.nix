{
  perSystem.treefmt.programs.yamlfmt.enable = true;

  flake.modules = {
    nixvim.dev.plugins.lsp.servers.yamlls.enable = true;
    homeManager.dev =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ yaml-language-server ];
      };
  };

}
