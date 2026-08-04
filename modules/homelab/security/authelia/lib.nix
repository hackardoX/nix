{ config, lib, ... }:
let
  hashedSecretsDir = "/var/lib/data/authelia/hashed-oidc-secrets";

  mkAllowedOrigins =
    clients:
    lib.unique (
      lib.concatLists (
        lib.mapAttrsToList (
          _: c: map (uri: lib.head (lib.match "(https?://[^/]+).*" uri)) c.redirectUris
        ) clients
      )
    );

  mkOidcClientYaml =
    name: client:
    let
      meta = config.flake.meta.oidc-clients.${name};
      extraLines = client.extraYamlLines or [ ];
      hasAuthMethodOverride = lib.any (lib.hasPrefix "token_endpoint_auth_method") extraLines;
      defaultAuthMethodLine = lib.optional (
        !hasAuthMethodOverride
      ) ''token_endpoint_auth_method: "client_secret_post"'';
      allExtraLines = defaultAuthMethodLine ++ extraLines;
      extraYaml = lib.concatMapStringsSep "\n  " (line: line) allExtraLines;
    in
    ''
      - client_id: "${meta.clientId}"
        client_name: "${meta.clientName}"
        public: false
        authorization_policy: "${client.policy}"
        ${extraYaml}
        client_secret: {{ secret "${hashedSecretsDir}/${name}_oidc_secret" | msquote }}
        redirect_uris:
          ${lib.concatMapStringsSep "\n    " (u: ''- "${u}"'') client.redirectUris}
        scopes:
          - "openid"
          - "profile"
          - "email"
    '';
in
{
  flake.lib.authelia = {
    inherit mkAllowedOrigins mkOidcClientYaml;
  };
}
