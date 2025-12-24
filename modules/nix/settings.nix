{
  inputs,
  lib,
  ...
}:
let
  nixConfig =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.git ];

      nix =
        let
          flakeInputs = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;

          users = [
            "root"
            "@wheel"
            "nix-builder"
            config.system.primaryUser
          ];
        in
        {
          registry = lib.pipe flakeInputs [
            (lib.mapAttrs (_: flake: { inherit flake; }))
            (x: lib.removeAttrs x [ "nixpkgs-unstable" ])
          ];
          nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;
          channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.

          settings = {
            accept-flake-config = lib.mkForce false;
            allowed-users = users;
            auto-optimise-store = pkgs.stdenv.hostPlatform.isLinux;
            builders-use-substitutes = true;
            download-buffer-size = 500000000;
            experimental-features = [
              "auto-allocate-uids"
              "ca-derivations"
              "dynamic-derivations"
              "flakes"
              "nix-command"
              "pipe-operators"
              "recursive-nix"
            ];
            # Prevent builds failing just because we can't contact a substituter
            fallback = true;
            flake-registry = "/etc/nix/registry.json";
            http-connections = 25;
            keep-derivations = true;
            keep-going = true;
            keep-outputs = true;
            log-lines = 50;
            preallocate-contents = true;
            # https://github.com/NixOS/nix/issues/12698
            sandbox = "relaxed"; # to be replaced with true once fixed
            trusted-users = users;
            warn-dirty = false;

            allowed-impure-host-deps = [
              # Only wanted to add this for darwin from nixos
              # But, apparently using option wipes out all the other in the default list
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

            build-users-group = "nixbld";

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

          optimise.automatic = true;
        };
    };
in
{
  flake.modules.nixos.base = nixConfig;
  flake.modules.darwin.base = nixConfig;
}
