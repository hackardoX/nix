{
  lib,
  inputs,
  namespace,
  ...
}:

let
  myHosts = lib.filterAttrs (_key: host: (host.config.${namespace}.user.name or null) != null) (
    inputs.self.darwinConfigurations or { }
  );
  myHostsConfig = lib.foldl' (
    acc: name:
    let
      remote = myHosts.${name};
      remoteUserName = remote.config.${namespace}.user.name;
    in
    acc
    // {
      ${name} = {
        config = ''
          Host ${name}
          Hostname ${name}.local
          User ${remoteUserName}
          ForwardAgent yes
        '';
      };
    }
  ) { } (builtins.attrNames myHosts);
in
myHostsConfig
