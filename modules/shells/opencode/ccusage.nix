{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccusage ];
    };
}
