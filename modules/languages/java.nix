{
  flake.modules.homeManager.dev = {
    programs.java.enable = true;
  };

  flake.modules.nixvim.dev = {
    plugins.lsp.servers.jdtls.enable = true;
  };
}
