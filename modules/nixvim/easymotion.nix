{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPlugins = [ pkgs.vimPlugins.vim-easymotion ];
    };
}
