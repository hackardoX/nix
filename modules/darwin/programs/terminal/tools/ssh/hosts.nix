{
  lib,
  inputs,
  namespace,
  ...
}:

let
  my-other-hosts = lib.filterAttrs (
    _key: host: (host.config.${namespace}.user.name or null) != null
  ) (inputs.self.darwinConfigurations or { });
  my-other-hosts-config = lib.foldl' (
    acc: name:
    let
      remote = my-other-hosts.${name};
      remote-user-name = remote.config.${namespace}.user.name;
    in
    acc
    // {
      ${name} = {
        config = ''
          Host ${name}
          Hostname ${name}.local
          User ${remote-user-name}
          ForwardAgent yes
        '';
      };
    }
  ) { } (builtins.attrNames my-other-hosts);
in
my-other-hosts-config
