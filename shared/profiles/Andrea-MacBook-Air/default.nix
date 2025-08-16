{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) disabled enabled fromBase64;
  user = config.${namespace}.user.name; # "aaccardo";
  hosts = {
    "hetzner_cloud_debian.8gb.hel1.1" = {
      forwardAgent = true;
      hostname = "46.62.149.89";
      identitiesOnly = true;
      user = "aaccardo";
    };
    "github_authorisation" = {
      forwardAgent = false;
      identitiesOnly = true;
    };
    # TODO: Find a way to automate this. It does not work right now
    # myHosts = (
    #   _key: host: (host.config.${namespace}.user.name or null) != null
    # ) (inputs.self.darwinConfigurations or { });
    "Andrea-MacBook-Air" = {
      forwardAgent = true;
      hostname = "Andrea-MacBook-Air.local";
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
      containerization = {
        enable = true;
        variants = [
          "podman"
          "docker"
        ];
      };
      nixEnable = true;
      sqlEnable = true;
      git = {
        user = "andrea11";
        inherit email;
      };
      ssh = {
        allowedSigners = [
          "${email} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsOzI1TFwbRy/GgE2/fNJR8B7gfIogp//2kDJ7D1uSB"
        ];
        hosts = lib.mapAttrs (name: hostConfig: {
          identityFile = "/Users/${user}/.ssh/${name}.pub";
          hostname = lib.mkIf (hostConfig ? hostname) hostConfig.hostname;
          user = lib.mkIf (hostConfig ? user) hostConfig.user;
          forwardAgent = lib.mkIf (hostConfig ? forwardAgent) hostConfig.forwardAgent;
          identitiesOnly = lib.mkIf (hostConfig ? identitiesOnly) hostConfig.identitiesOnly;
          port = lib.mkIf (hostConfig ? port) hostConfig.port;
        }) hosts;
        knownHosts = lib.mapAttrs (name: hostConfig: {
          hostNames = if (hostConfig ? hostname) then [ hostConfig.hostname ] else [ ];
          publicKeyFile = "/Users/${user}/.ssh/${name}.pub";
        }) hosts;
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
