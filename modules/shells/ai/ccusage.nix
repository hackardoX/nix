{ inputs, ... }:
{
  flake.modules.homeManager.ccusage =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccusage ];

      xdg.configFile."claude/ccusage.json".text = builtins.toJSON {
        "$schema" = "https://ccusage.com/config-schema.json";
        defaults.pricingOverrides = {
          lumo-max = {
            inputCostPerToken = 3.0e-6;
            outputCostPerToken = 6.0e-6;
            cacheReadInputTokenCost = 1.0e-6;
            maxInputTokens = 256000;
          };
          lumo-lite = {
            inputCostPerToken = 1.0e-6;
            outputCostPerToken = 4.0e-6;
            cacheReadInputTokenCost = 0.25e-6;
            maxInputTokens = 256000;
          };
        };
      };
    };
}
