{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nodejs ];
    };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        typescript
        typescript-language-server
      ];

      plugins = {
        lsp.servers = {
          biome.enable = true;
          eslint.enable = true;
        };
        typescript-tools = {
          enable = true;
          settings.single_file_support = true;
        };
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              typescript = [
                "biome"
                "eslint_d"
              ];
              javascript = [
                "biome"
                "eslint_d"
              ];
            };
            formatters = {
              biome = {
                command = "${pkgs.biome}/bin/biome";
              };
              eslint_d = {
                command = "${pkgs.eslint_d}/bin/eslint_d";
              };
            };
          };
        };
      };
    };
}
