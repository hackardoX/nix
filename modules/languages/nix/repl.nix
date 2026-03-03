{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        nix
      ];

      plugins.iron = {
        settings = {
          config = {
            repl_definition = {
              nix.command = [
                "nix"
                "repl"
                "<nixpkgs>"
              ];
            };
          };
        };
      };

      keymaps = [
        {
          mode = "n";
          key = "<leader>rn";
          action = "<cmd>IronRepl nix<cr>";
          options.desc = "Force start Nix REPL";
        }
      ];
    };
}
