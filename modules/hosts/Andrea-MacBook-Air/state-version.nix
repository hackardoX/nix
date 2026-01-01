{
  configurations.darwin.Andrea-MacBook-Air.module =
    { config, ... }:
    {
      system.stateVersion = 5;
      home-manager.users.${config.system.primaryUser}.home.stateVersion = "24.11";
    };
}
