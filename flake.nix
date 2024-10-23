{
  description = "Starter Configuration for MacOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      darwin,
      nixpkgs,
    }@inputs:
    let
      user = "aaccardo";
      darwinSystems = [ "aarch64-darwin" ];
      # forAllSystems = f: nixpkgs.lib.genAttrs (darwinSystems) f;
      # mkDevShell =
      #   system:
      #   let
      #     pkgs = nixpkgs.legacyPackages.${system};
      #   in
      #   {
      #     default =
      #       with pkgs;
      #       mkShell {
      #         nativeBuildInputs = with pkgs; [
      #           bashInteractive
      #           git
      #         ];
      #         shellHook = ''
      #           export EDITOR=vim
      #         '';
      #       };
      #   };
      mkApp = scriptName: system: {
        type = "app";
        program = "${
          (nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
            #!/usr/bin/env bash
            PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
            echo "Running ${scriptName} for ${system}"
            exec ${self}/apps/${system}/${scriptName}
          '')
        }/bin/${scriptName}";
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "rollback" = mkApp "rollback" system;
      };
    in
    {
      # devShell = forAllSystems mkDevShell;
      apps = nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (
        system:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs ++ {
            inherit user system;
          };
          modules = [
            ./hosts/darwin
          ];
          imports = [
            ./modules/home-manager/custom-home-manager.nix
            ./modules/homebrew/custom-homebrew.nix
            ./modules/dock/custom-dock.nix
          ];
        }
      );
    };
}
