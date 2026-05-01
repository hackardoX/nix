{ inputs, ... }:
{
  flake.modules.darwin.laptop = darwinArgs: {
    imports = [ inputs.nix-apple-container.darwinModules.default ];
    services.containerization = {
      enable = true;
      user = darwinArgs.config.system.primaryUser;
    };
    homebrew.brews = [
      "container-compose"
    ];
  };
}
