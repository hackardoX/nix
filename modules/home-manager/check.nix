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
                  _module.args.osConfig = {
                    system.primaryUser = "check-user";
                  };
                }
              ];
            };
          in
          hmConfig.config.home-files;
      };
    };
}
