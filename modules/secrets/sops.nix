{ inputs, lib, ... }:
let
  sopsKeyPath = "/var/lib/sops/age-key.txt";
in
{
  flake.modules.nixos.sops = {
    imports = [ inputs.sops-nix.nixosModules.default ];
    sops.age.keyFile = sopsKeyPath;
  };

  flake.modules.darwin.sops = {
    imports = [ inputs.sops-nix.darwinModules.default ];
    sops.age.keyFile = sopsKeyPath;
  };

  flake.modules.homeManager.sops =
    hmArgs@{ pkgs, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.default ];
      sops.age.keyFile = "${hmArgs.config.home.homeDirectory}/.config/sops/age/keys.txt";
      xdg.configFile."sops/age/keys.txt".source = hmArgs.config.lib.file.mkOutOfStoreSymlink sopsKeyPath;
      home.activation.reloadSystemdBeforeSops = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
        inputs.home-manager.lib.hm.dag.entryBetween [ "sops-nix" ] [ "reloadSystemd" ] ''
          # no-op: forces sops-nix to run after linkGeneration and reloadSystemd
        ''
      );
    };

  flake.modules.homeManager.sops-cli =
    hmArgs@{ pkgs, ... }:
    let
      protonPassEnabled = hmArgs.config.services.proton-pass-agent.enable or false;
      onePasswordEnabled = hmArgs.config.programs._1password-shell-plugins.enable or false;
    in
    {
      home = {
        packages = [ pkgs.sops ];
        shellAliases.sops = lib.mkIf (protonPassEnabled || onePasswordEnabled) (
          if protonPassEnabled then
            "SOPS_AGE_KEY=\"$(pass-cli item view 'pass://Development/Admin Age Key/note')\" sops"
          else
            "SOPS_AGE_KEY=\"$(op read 'op://Development/Admin Age Key/notesPlain')\" sops"
        );
      };
    };
}
