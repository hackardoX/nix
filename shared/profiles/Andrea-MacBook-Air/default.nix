{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
  user = config.${namespace}.user.name; # "aaccardo";
  hosts = {
    "oracle_cloud_a1-flex.4ocpu.24gb" = {
      forwardAgent = true;
      hostname = "89.168.58.86";
      identitiesOnly = true;
      user = "ubuntu";
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

in
{
  suites = {
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
    };
    development = {
      enable = true;
      aiEnable = true;
      dockerEnable = true;
      nixEnable = true;
      sqlEnable = true;
      git = {
        user = "andrea11";
        email = "10788630+andrea11@users.noreply.github.com";
      };
      ssh = {
        allowedSigners = [
          "10788630+andrea11@users.noreply.github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsOzI1TFwbRy/GgE2/fNJR8B7gfIogp//2kDJ7D1uSB"
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
    music = enabled;
  };
}
