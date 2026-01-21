{ inputs, lib, ... }:
let
  polyModule =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.git ];

      determinate-nix = {
        customSettings =
          let
            users = [
              "root"
              "@wheel"
              "nix-builder"
              config.system.primaryUser
            ];
          in
          {
            accept-flake-config = lib.mkForce false;
            allowed-users = users;
            auto-optimise-store = pkgs.stdenv.hostPlatform.isLinux;
            builders-use-substitutes = true;
            download-buffer-size = 500000000;
            experimental-features = [
              "auto-allocate-uids"
              "ca-derivations"
              "dynamic-derivations"
              "pipe-operators"
              "recursive-nix"
            ];
            fallback = true;
            flake-registry = "/etc/nix/registry.json";
            http-connections = 25;
            keep-derivations = true;
            keep-going = true;
            keep-outputs = true;
            log-lines = 50;
            preallocate-contents = true;
            sandbox = "relaxed";
            trusted-users = users;
            warn-dirty = false;

            allowed-impure-host-deps = [
              "/bin/sh"
              "/dev/random"
              "/dev/urandom"
              "/dev/zero"
              "/usr/bin/ditto"
              "/usr/lib/libSystem.B.dylib"
              "/usr/lib/libc.dylib"
              "/usr/lib/system/libunc.dylib"
            ];

            use-xdg-base-directories = true;

            extra-sandbox-paths = [
              "/System/Library/Frameworks"
              "/System/Library/PrivateFrameworks"
              "/usr/lib"
              "/private/tmp"
              "/private/var/tmp"
              "/usr/bin/env"
            ];
            extra-system-features = [ "recursive-nix" ];
          };
      };
    };
in
{
  flake.modules.nixos.base = {
    imports = [
      inputs.determinate.nixosModules.default
      polyModule
    ];
  };

  flake.modules.darwin.base = {
    imports = [
      inputs.determinate.darwinModules.default
      polyModule
    ];
    nix.enable = false;
  };
}
