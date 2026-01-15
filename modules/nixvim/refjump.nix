{ inputs, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPlugins = [
        (pkgs.vimUtils.buildVimPlugin {
          pname = "refjump-nvim";
          version = "unstable";
          src = inputs.refjump-nvim;
        })
      ];

      extraConfigLua = ''
        require('refjump').setup()
      '';
    };
}
