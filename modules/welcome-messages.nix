{
  flake.modules = {
    nixvim.dev = {
      extraConfigLua =
        # lua
        ''
          vim.opt.shortmess:append("I")
        '';
    };
  };
}
