{ lib, self, ... }:
{
  perSystem.treefmt.programs = {
    nixf-diagnose.enable = true;
    statix = {
      enable = true;
    };
  };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        nixfmt
      ];

      plugins.conform-nvim.settings = {
        formatters_by_ft.nix = [ "nixfmt" ];
        formatters.nixfmt.command = "${pkgs.nixfmt}/bin/nixfmt";
      };

      plugins.lsp.servers = {
        nixd.enable = true;
        statix.enable = true;
      };
    };
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      programs.opencode = {
        extraPackages = with pkgs; [
          nixd
          nixfmt
        ];
        settings = {
          formatter = {
            nixfmt = {
              command = [
                (lib.getExe pkgs.nixfmt)
                "$FILE"
              ];
              extensions = [ ".nix" ];
            };
          };
          lsp = {
            nixd =
              let
                flakePath = ''builtins.getFlake "${self}"'';

                nixosHostname = lib.head (lib.attrNames self.nixosConfigurations);
                darwinHostname = lib.head (lib.attrNames self.darwinConfigurations);
                hmUser = lib.head (lib.attrNames self.homeConfigurations);

                nixosExpr = lib.optionalAttrs (self.nixosConfigurations != { }) {
                  nixos.expr = "(${flakePath}).nixosConfigurations.${nixosHostname}.options";
                };

                darwinExpr = lib.optionalAttrs (self.darwinConfigurations != { }) {
                  nix-darwin.expr = "(${flakePath}).darwinConfigurations.${darwinHostname}.options";
                };

                hmExpr = lib.optionalAttrs (self.homeConfigurations != { }) {
                  home-manager.expr = "(${flakePath}).homeConfigurations.\"${hmUser}\".options";
                };
              in
              {
                command = [ (lib.getExe pkgs.nixd) ];
                extensions = [ ".nix" ];
                initialization = {
                  formatting = {
                    command = [ (lib.getExe pkgs.nixfmt) ];
                  };
                  options = nixosExpr // darwinExpr // hmExpr;
                };
              };
          };
        };
      };
    };
}
