{
  inputs,
  lib,
  ...
}:
let
  nixConfigBase =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.git ];

      nix =
        let
          flakeInputs = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;
          users = [
            "root"
            "@wheel"
          ];
        in
        {
          registry = lib.pipe flakeInputs [
            (lib.mapAttrs (_: flake: { inherit flake; }))
            (x: lib.removeAttrs x [ "nixpkgs-unstable" ])
          ];

          nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

          channel.enable = false;

          settings = {
            experimental-features = [
              "flakes"
              "nix-command"
            ];

            allowed-users = users;
            trusted-users = users;

            sandbox = lib.mkDefault true;

            accept-flake-config = false;
            flake-registry = "/etc/nix/registry.json";

            fallback = true;
            keep-going = true;

            use-xdg-base-directories = true;
          };

          optimise.automatic = true;
        };
    };

  nixConfigLaptop =
    { config, ... }:
    let
      users = [
        "root"
        "@wheel"
        "nix-builder"
        "@admin"
        config.system.primaryUser
      ];
    in
    {
      nix.settings = {
        experimental-features = [
          "auto-allocate-uids"
          "ca-derivations"
          "dynamic-derivations"
          "flakes"
          "nix-command"
          "pipe-operators"
          "recursive-nix"
        ];

        allowed-users = users;
        trusted-users = users;
        download-buffer-size = 500000000;
        http-connections = 25;
        preallocate-contents = true;

        keep-derivations = true;
        keep-outputs = true;
        log-lines = 50;
        warn-dirty = false;

        # https://github.com/NixOS/nix/issues/12698
        sandbox = "relaxed";

        extra-system-features = [ "recursive-nix" ];
      };

    };

  nixConfigLaptopDarwin = {
    nix = {
      settings = {
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

        build-users-group = "nixbld";

        extra-sandbox-paths = [
          "/System/Library/Frameworks"
          "/System/Library/PrivateFrameworks"
          "/usr/lib"
          "/private/tmp"
          "/private/var/tmp"
          "/usr/bin/env"
        ];
      };
    };
  };
in
{
  flake.modules.nixos.base = nixConfigBase;
  flake.modules.darwin.base = nixConfigBase;

  flake.modules.nixos.laptop = nixConfigLaptop;
  flake.modules.darwin.laptop = lib.mkMerge [
    nixConfigLaptop
    nixConfigLaptopDarwin
  ];
}
