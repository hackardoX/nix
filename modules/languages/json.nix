{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        fx
        jd-diff-patch
        jq
      ];
    };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        prettierd
      ];

      plugins.conform-nvim.settings = {
        formatters_by_ft = {
          json = [ "prettierd" ];
        };
        formatters = {
          prettierd.command = "${pkgs.prettierd}/bin/prettierd";
        };
      };
    };
}
