{
  flake.modules.nixvim.dev = {
    extraConfigLua = ''
      vim.opt.shortmess:append("I")
    '';
  };
}
