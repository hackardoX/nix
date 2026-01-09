{
  flake.modules = {
    nixvim.base.plugins.lsp.servers = {
      nixd.enable = true;
      statix.enable = true;
    };

    homeManager.base =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          nixd
          statix
        ];
      };
  };
}
