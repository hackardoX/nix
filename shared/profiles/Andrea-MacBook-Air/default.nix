{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) disabled enabled fromBase64;
  hosts = {
    "hetzner_cloud_debian.8gb.hel1.1" = {
      forwardAgent = true;
      hostname = "46.62.149.89";
      identityFile = config.programs.onepassword-secrets.secretPaths.hetznerCloudKey;
      identitiesOnly = true;
      user = "aaccardo";
    };
    "github_authorisation" = {
      hostname = "github.com";
      forwardAgent = false;
      identityFile = config.programs.onepassword-secrets.secretPaths.githubAuthorisation;
      identitiesOnly = true;
    };
    "Andrea-MacBook-Air" = {
      forwardAgent = true;
      hostname = "Andrea-MacBook-Air.local";
      identityFile = config.programs.onepassword-secrets.secretPaths.andreaMacBookAirPublicKey;
      identitiesOnly = true;
      user = "aaccardo";
    };
  };
  email = fromBase64 "aGFja2FyZG9AZ21haWwuY29t";

in
{
  suites = {
    art = disabled;
    business = enabled;
    common = {
      enable = true;
      openssh = {
        enable = true;
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyyfmn+7pOkf7UXgWV6BzceLpJk49AT07XgCnnbd323"
        ];
        # TODO: impossible to use keys from outside the flake repo. Find a way to solve this
        # authorizedKeyFiles = (lib.map (host: "/Users/${user}/.ssh/${host}.pub") myHosts);
      };
      rosetta.enable = false;
    };
    desktop = enabled;
    development = {
      enable = true;
      aiEnable = true;
      mobileEnable = true;
      containerization = {
        enable = true;
        variants = [
          "podman"
          "docker"
        ];
      };
      git = {
        user = "hackardoX";
        inherit email;
      };
      nixEnable = true;
      sqlEnable = true;
      ssh = {
        allowedSigners = [
          "${email} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsOzI1TFwbRy/GgE2/fNJR8B7gfIogp//2kDJ7D1uSB"
        ];
        hosts = lib.mapAttrs (_name: hostConfig: {
          identityFile = lib.mkIf (hostConfig ? identityFile) hostConfig.identityFile;
          hostname = lib.mkIf (hostConfig ? hostname) hostConfig.hostname;
          user = lib.mkIf (hostConfig ? user) hostConfig.user;
          forwardAgent = lib.mkIf (hostConfig ? forwardAgent) hostConfig.forwardAgent;
          identitiesOnly = lib.mkIf (hostConfig ? identitiesOnly) hostConfig.identitiesOnly;
          port = lib.mkIf (hostConfig ? port) hostConfig.port;
        }) hosts;
        knownHosts = lib.flatten (
          lib.mapAttrsToList (
            _name: hostConfig: if hostConfig ? hostname then [ hostConfig.hostname ] else [ ]
          ) hosts
        );
      };
    };
    games = disabled;
    music = enabled;
    networking = disabled;
    photo = disabled;
    social = enabled;
    video = enabled;
  };
}
