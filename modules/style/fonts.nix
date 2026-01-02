{ config, lib, ... }:
{
  options.fonts.default = lib.mkOption {
    type = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "meslo-lg";
          readOnly = true;
          description = "Font package name in nerd-fonts";
        };
        family = lib.mkOption {
          type = lib.types.str;
          default = "MesloLGL Nerd Font";
          readOnly = true;
          description = "Font family name for applications";
        };
      };
    };
    default = { };
  };

  config.flake.modules = {
    darwin.base =
      { pkgs, ... }:
      {
        fonts.packages = [ pkgs.nerd-fonts.${config.fonts.default.name} ];
        system.defaults.NSGlobalDomain.AppleFontSmoothing = 1;
      };

    homeManager.base =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.nerd-fonts.${config.fonts.default.name} ];
      };
  };
}
