{ config, ... }: {
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        fx
        jd-diff-patch
        jq
      ];
    };

  flake.modules.nixvim.dev = {
    plugins.conform-nvim.luaConfig.post = config.flake.lib.formatRouting.post "web" [
      "json"
      "jsonc"
    ];
  };
}
