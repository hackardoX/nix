{
  flake.modules.nixvim.dev = {
    plugins.treesitter.folding.enable = true;
    opts.foldlevel = 99;
  };
}
