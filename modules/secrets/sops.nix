{ inputs, ... }:
let
  sopsKeyPath = "/var/lib/sops/age-key.txt";
in
{
  flake.modules.nixos.base = {
    imports = [ inputs.sops-nix.nixosModules.default ];
    sops.age.keyFile = sopsKeyPath;
  };

  flake.modules.darwin.base = {
    imports = [ inputs.sops-nix.darwinModules.default ];
    sops.age.keyFile = sopsKeyPath;
  };

  flake.modules.homeManager.base = hmArgs: {
    imports = [ inputs.sops-nix.homeManagerModules.default ];
    sops.age.keyFile = "${hmArgs.config.home.homeDirectory}/.config/sops/age/keys.txt";
    home.file.".config/sops/age/keys.txt".source =
      hmArgs.config.lib.file.mkOutOfStoreSymlink sopsKeyPath;
  };

  flake.modules.homeManager.hackardo = { pkgs, ... }: {
    home.packages = [ pkgs.sops ];
    home.shellAliases.sops = "SOPS_AGE_KEY=\"$(op read 'op://Development/Admin Age Key/notesPlain')\" sops";
  };
}
