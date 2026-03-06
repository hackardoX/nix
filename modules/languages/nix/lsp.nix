{
  flake.modules.nixvim.dev = {
    plugins.lsp.servers = {
      nixd.enable = true;
      statix.enable = true;
    };
  };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nixd
        statix
      ];
    };
}
