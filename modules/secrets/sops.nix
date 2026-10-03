{ inputs, lib, ... }:
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

  flake.modules.homeManager.base =
    hmArgs@{ pkgs, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.default ];
      sops.age.keyFile = "${hmArgs.config.home.homeDirectory}/.config/sops/age/keys.txt";
      home.activation.reloadSystemdBeforeSops = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
        inputs.home-manager.lib.hm.dag.entryBetween [ "sops-nix" ] [ "reloadSystemd" ] ''
          # no-op: forces sops-nix to run after linkGeneration and reloadSystemd
        ''
      );
    };

  flake.modules.homeManager.hackardo =
    hmArgs@{ pkgs, ... }:
    {
      home = {
        packages = [ pkgs.sops ];
        shellAliases.sops = "SOPS_AGE_KEY=\"$(op read 'op://Development/Admin Age Key/notesPlain')\" sops";
        file.".config/sops/age/keys.txt".source = hmArgs.config.lib.file.mkOutOfStoreSymlink sopsKeyPath;
      };
    };
}
