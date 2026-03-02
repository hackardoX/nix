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
}
