{ inputs, ... }:
{
  flake.modules.homeManager.ccusage =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccusage ];
    };
}
