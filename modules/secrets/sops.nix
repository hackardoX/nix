{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.sops-nix.nixosModules.default ];
    sops.age.keyFile = "/var/lib/sops/age-key.txt";
  };

  flake.modules.darwin.base = {
    imports = [ inputs.sops-nix.darwinModules.default ];
    sops.age.keyFile = "/var/lib/sops/age-key.txt";
  };

  flake.modules.homeManager.base = hmArgs: {
    imports = [ inputs.sops-nix.homeManagerModules.default ];
    sops.age.keyFile = "${hmArgs.config.home.homeDirectory}/.config/sops/age/keys.txt";
  };
}
