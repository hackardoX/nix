{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.homelab.check) mkCheck;
  authelia = config.flake.lib.authelia;
  hashedDir = authelia.hashedSecretsDir;
  initScript = host.systemd.services.authelia-init.script;

  # --- authelia-secrets-dir ----------------------------------------------

  autheliaFailures =
    lib.optional (
      !lib.any (r: lib.hasPrefix "d ${hashedDir} " r) host.systemd.tmpfiles.rules
    ) "systemd.tmpfiles.rules has no rule creating ${hashedDir}"
    ++ lib.optional (
      !lib.hasInfix "${hashedDir}/" initScript
    ) "systemd.services.authelia-init does not write under ${hashedDir}"
    ++ lib.concatLists (
      lib.mapAttrsToList (
        name: client:
        let
          secretFile = "${hashedDir}/${name}_oidc_secret";
        in
        lib.optional (
          !lib.hasInfix secretFile initScript
        ) "authelia-init does not write ${secretFile} for OIDC client ${name}"
        ++ lib.optional (
          !lib.hasInfix secretFile (authelia.mkOidcClientYaml name client)
        ) "mkOidcClientYaml ${name} does not read ${secretFile}"
      ) config.flake.meta.oidc-clients
    );

  # --- authelia-lib ------------------------------------------------------

  libTests = {
    testAllowedOriginsDedupAndStripPath = {
      expr = authelia.mkAllowedOrigins {
        a.redirectUris = [
          "https://x.example/cb"
          "https://x.example/other"
          "http://y.example:8080/p"
        ];
        b.redirectUris = [
          "ftp://z.example/file"
          "https://x.example/"
        ];
      };
      expected = [
        "https://x.example"
        "http://y.example:8080"
      ];
    };

    testOidcClientYamlDefaults =
      let
        yaml = authelia.mkOidcClientYaml "tandoor" {
          policy = "two_factor";
          redirectUris = [ "https://a.example/cb" ];
        };
      in
      {
        # Lists the needles that are missing from the generated YAML.
        expr = lib.filter (needle: !lib.hasInfix needle yaml) [
          ''client_id: "tandoor"''
          ''authorization_policy: "two_factor"''
          ''client_secret: {{ secret "${hashedDir}/tandoor_oidc_secret" | msquote }}''
          ''token_endpoint_auth_method: "client_secret_post"''
          ''- "https://a.example/cb"''
        ];
        expected = [ ];
      };

    testOidcClientYamlAuthMethodOverride =
      let
        yaml = authelia.mkOidcClientYaml "tandoor" {
          policy = "two_factor";
          redirectUris = [ "https://a.example/cb" ];
          extraYamlLines = [ ''token_endpoint_auth_method: "client_secret_basic"'' ];
        };
      in
      {
        expr = {
          defaultPresent = lib.hasInfix "client_secret_post" yaml;
          overridePresent = lib.hasInfix "client_secret_basic" yaml;
        };
        expected = {
          defaultPresent = false;
          overridePresent = true;
        };
      };
  };

  libFailures =
    let
      results = lib.runTests libTests;
    in
    lib.optional (results != [ ]) (lib.generators.toPretty { } results);
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        "homelab/authelia-secrets-dir" = mkCheck pkgs "authelia-secrets-dir" autheliaFailures;
        "homelab/authelia-lib" = mkCheck pkgs "authelia-lib" libFailures;
      };
    };
}
