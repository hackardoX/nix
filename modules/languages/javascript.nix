{
  flake.modules.nixvim.base.plugins = {
    lsp.servers.eslint.enable = true;
    typescript-tools.enable = true;
    perSystem.treefmt.programs.biome = {
      enable = true;
      settings = {
        formatter.formatWithErrors = true;
        assist = {
          actions.source.useSortedAttributes = "on";
        };
        css = {
          formatter.enabled = true;
          parser.cssModules = true;
        };
        linter = {
          rules.nursery.useSortedClasses = {
            level = "error";
            fix = "safe";
            options = { };
          };
        };
      };
    };
  };
}
