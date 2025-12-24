{
  flake.modules = {
    nixvim.base = {
      extraConfigLua =
        # lua
        ''
          vim.opt.shortmess:append("I")
        '';
    };
  };
}
