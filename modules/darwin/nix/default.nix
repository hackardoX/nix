{
  config,
  lib,
  inputs,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) disabled mkBoolOpt mkOpt;
  cfg = config.${namespace}.nix;
in
{
  options.${namespace}.nix = {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
    package = mkOpt lib.types.package pkgs.nixVersions.latest "Which nix package to use.";
  };

  config = lib.mkIf cfg.enable {
    assertions =
      let
        # TODO: This is a safeguard for now, but we should probably
        # Registry does not allow keys starting with a number or symbols
        invalidFlakes = builtins.attrNames (
          lib.filterAttrs (
            name: _value: builtins.isNull (builtins.match "^[A-Za-z].*" name)
          ) config.nix.registry

        );
      in
      [
        {
          assertion = builtins.length invalidFlakes == 0;
          message = "Registry contains a flake with an invalid name (first character must be a letter): ${builtins.toJSON invalidFlakes}";
        }
      ];

    # faster rebuilding
    documentation = {
      doc = disabled;
      info = disabled;
      man.enable = lib.mkDefault true;
    };

    environment = {
      etc = with inputs; {
        "nix-darwin".source = self;
      };

      systemPackages = with pkgs; [
        # FIXME: broken pkg
        # cachix
        git
        nix-prefetch-git
      ];
    };

    # Shared config options
    # Check corresponding nix-darwin imported module
    nix =
      let
        mappedRegistry = lib.pipe inputs [
          (lib.filterAttrs (_: lib.isType "flake"))
          (lib.mapAttrs (_: flake: { inherit flake; }))
          (x: lib.removeAttrs x [ "nixpkgs-unstable" ])
        ];

        users = [
          "root"
          "@wheel"
          "nix-builder"
          config.${namespace}.user.name
        ];
      in
      {
        inherit (cfg) package;

        buildMachines =
          let
            sshUser = config.${namespace}.user.name;
            protocol = "ssh";
            supportedFeatures = [
              "benchmark"
              "big-parallel"
              "nixos-test"
            ];
          in
          [
            {
              inherit protocol sshUser;
              systems = [
                "aarch64-darwin"
              ];
              hostName = "Andrea-MacBook-Air.local";
              maxJobs = 4;
              speedFactor = 3;
              supportedFeatures = supportedFeatures ++ [ "apple-virt" ];
              sshKey = "/Users/${config.${namespace}.user.name}/.ssh/Andrea-MacBook-Air";
            }
          ];

        checkConfig = true;
        distributedBuilds = true;

        nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

        optimise.automatic = true;

        # pin the registry to avoid downloading and evaluating a new nixpkgs version every time
        # this will add each flake input as a registry to make nix3 commands consistent with your flake
        registry = mappedRegistry;

        settings = {
          allowed-users = users;
          auto-optimise-store = pkgs.stdenv.hostPlatform.isLinux;
          builders-use-substitutes = true;
          download-buffer-size = 500000000;
          experimental-features = [
            "nix-command"
            "flakes"
            "ca-derivations"
            "auto-allocate-uids"
            "pipe-operators"
            "dynamic-derivations"
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

          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://nixpkgs-unfree.cachix.org"
            "https://numtide.cachix.org"
          ];

          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "aaccardo.cachix.org-1:lonn0TzLICqhzw+srQyQsMQ4HRgrTuw2ckAQOsKDajs="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
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
        };

        # Nix-Darwin config options
        # Options that aren't supported through nix-darwin
        extraOptions = ''
          # bail early on missing cache hits
          connect-timeout = 10
          keep-going = true
        '';

        gc = {
          interval = [
            {
              Hour = 3;
              Minute = 15;
              # Weekday = 1;
            }
          ];
        };

        # Optimize nix store after cleaning
        optimise.interval = lib.lists.forEach config.nix.gc.interval (e: {
          inherit (e) Minute; # Weekday;
          Hour = e.Hour + 1;
        });

        # NOTE: not sure if i saw any benefits changing this
        # daemonProcessType = "Adaptive";
      };
  };
}
