{
  config,
  inputs,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        base =
          let
            hmConfig = inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                config.flake.modules.homeManager.base
                {
                  home.stateVersion = "24.11";
                  home.username = "check-user";
                }
              ];
              extraSpecialArgs.homeConfig = {
                catppuccin = {
                  enable = true;
                  flavor = "mocha";
                };
              };
            };
          in
          hmConfig.config.home-files;
      };
    };
}
