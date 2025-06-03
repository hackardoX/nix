{
  config,
  lib,
  inputs,
  namespace,
  ...
}:

let
  my-other-hosts = lib.filterAttrs (
    _key: host: (host.config.${namespace}.user.name or null) != null
  ) (inputs.self.darwinConfigurations or { });

  other-hosts = {
    "Oracle-Cloud-a1-flex.4ocpu.24gb" = {
      hostname = "89.168.58.86";
      user = "ubuntu";
      forwardAgent = true;
    };
    "github.com" = {
      forwardAgent = false;
      identitiesOnly = true;
    };
  };

  other-hosts-config = lib.foldl' (
    acc: name:
    let
      hostConfig = other-hosts.${name};
    in
    acc
    // {
      ${name} = {
        hostname = lib.mkIf (hostConfig ? hostname) hostConfig.hostname;
        user = lib.mkIf (hostConfig ? user) hostConfig.user;
        identitiesOnly = lib.mkIf (hostConfig ? identitiesOnly) hostConfig.identitiesOnly;
        forwardAgent = lib.mkIf (hostConfig ? forwardAgent) hostConfig.forwardAgent;
        identityFile = "/Users/${config.${namespace}.user.name}/.ssh/${name}.pub";
        port = lib.mkIf (hostConfig ? port) hostConfig.port;
      };
    }
  ) { } (builtins.attrNames other-hosts);

  my-other-hosts-config = lib.foldl' (
    acc: name:
    let
      remote = my-other-hosts.${name};
      remote-user-name = remote.config.${namespace}.user.name;
      remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;
      user-id = builtins.toString config.${namespace}.user.uid;
    in
    acc
    // {
      ${name} = {
        hostname = "${name}.local";
        user = remote-user-name;
        forwardAgent = true;
        identityFile = "/Users/${config.${namespace}.user.name}/.ssh/${name}.pub";
        port = config.${namespace}.programs.terminal.tools.ssh.port;
        remoteForwards =
          lib.optionals (config.services.gpg-agent.enable && remote.config.services.gpg-agent.enable)
            [
              "/run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra"
              "/run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh"
            ];
      };
    }
  ) { } (builtins.attrNames my-other-hosts);
in
other-hosts-config // my-other-hosts-config
