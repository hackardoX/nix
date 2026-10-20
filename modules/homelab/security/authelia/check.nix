{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  inherit (config.flake.lib.checks) mkCheck mkSystemdCheck;
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

  # --- validate-authelia (build-time, aarch64-linux only) ----------------
  # Runs the same `validate-config` command the authelia-default unit runs in
  # ExecStartPre, with the unit's own environment and credential names. Only
  # the inputs are replaced, and only for the sandbox:
  #   credentials and /run/secrets/* -> dummy files (the JWKS key is a real
  #                                     RSA key, because it is parsed)
  #   /var/lib/data/authelia         -> build dir (hashed client secrets)
  #   OIDC client secrets            -> real PBKDF2 hashes of dummy values,
  #                                     made like authelia-init makes them
  autheliaUnit = host.systemd.services.authelia-default;
  # Credential names are the left side of "name:/run/secrets/...".
  autheliaCredentials = map (
    c: lib.head (lib.splitString ":" c)
  ) autheliaUnit.serviceConfig.LoadCredential;
  # %d is the unit's credentials directory; the rest are /run/secrets paths.
  autheliaEnvExports = lib.mapAttrsToList (
    name: value:
    if lib.hasPrefix "%d/" value then
      ''export ${name}="$creds/${lib.removePrefix "%d/" value}"''
    else if lib.hasPrefix "/run/secrets/" value then
      ''export ${name}="$secrets/${lib.removePrefix "/run/secrets/" value}"''
    else
      "export ${name}=${lib.escapeShellArg value}"
  ) (lib.filterAttrs (n: _: n != "PATH") autheliaUnit.environment);
  autheliaEnvSecrets = lib.filter (lib.hasPrefix "/run/secrets/") (
    lib.attrValues (lib.filterAttrs (n: _: n != "PATH") autheliaUnit.environment)
  );
  # Relative to the dummy secrets dir: the authentication_backend users file.
  autheliaUsersRel = lib.removePrefix "/run/secrets/" host.services.authelia.instances.default.settings.authentication_backend.file.path;

  autheliaCredentialDummy =
    name:
    # Only the JWKS key is parsed as a key; the others are plain secrets.
    if name == "oidcIssuerPrivateKeyFile" then
      ''openssl genrsa -out "$creds/${name}" 2048 2>/dev/null''
    else
      ''openssl rand -hex 32 > "$creds/${name}"'';

  autheliaSecretDummy =
    path:
    let
      rel = lib.removePrefix "/run/secrets/" path;
    in
    ''
      mkdir -p "$(dirname "$secrets/${rel}")"
      openssl rand -hex 32 > "$secrets/${rel}"
    '';

  validateAuthelia =
    pkgs:
    pkgs.runCommand "homelab-validate-authelia"
      {
        nativeBuildInputs = [ pkgs.openssl ];
      }
      ''
        set -euo pipefail
        work=$PWD/work
        creds=$work/creds
        secrets=$work/secrets
        state=$work/state
        mkdir -p $creds $secrets $state/hashed-oidc-secrets $work/cfg

        # The unit's ExecStartPre is "<authelia> --config <a>,<b>,<c> validate-config".
        set -- ${autheliaUnit.serviceConfig.ExecStartPre}
        if [ "$#" -ne 4 ] || [ "$2" != --config ] || [ "$4" != validate-config ]; then
          echo "unexpected authelia-default ExecStartPre: $*" >&2
          exit 1
        fi
        bin=$1
        IFS=, read -r -a sources <<< "$3"

        ${lib.concatStringsSep "\n" (map autheliaCredentialDummy autheliaCredentials)}
        ${lib.concatStringsSep "\n" (map autheliaSecretDummy autheliaEnvSecrets)}
        mkdir -p "$(dirname "$secrets/${autheliaUsersRel}")"
        echo "users: {}" > "$secrets/${autheliaUsersRel}"

        # systemd sets this for the unit; the oidc-jwks template reads it.
        export CREDENTIALS_DIRECTORY=$creds
        ${lib.concatStringsSep "\n" autheliaEnvExports}

        configs=()
        for source in "''${sources[@]}"; do
          dst=$work/cfg/$(basename "$source")
          cp --no-preserve=mode "$source" "$dst"
          sed -i \
            -e "s#/run/secrets/#$secrets/#g" \
            -e "s#/var/lib/data/authelia#$state#g" \
            "$dst"
          configs+=("$dst")
        done

        sed -n "s#.*\($state/hashed-oidc-secrets/[^\" |]*\).*#\1#p" $work/cfg/* | sort -u | while IFS= read -r hashed; do
          "$bin" crypto hash generate pbkdf2 --variant sha512 --no-confirm \
            --password "$(openssl rand -hex 16)" \
            | sed -n 's/^Digest: //p' > "$hashed"
          [ -s "$hashed" ] || { echo "no PBKDF2 digest generated for $hashed" >&2; exit 1; }
        done

        config=$(IFS=,; echo "''${configs[*]}")
        "$bin" --config "$config" validate-config
        touch $out
      '';
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        "homelab/authelia-secrets-dir" = mkCheck pkgs "homelab/authelia-secrets-dir" autheliaFailures;
        "homelab/authelia-lib" = mkCheck pkgs "homelab/authelia-lib" libFailures;
      }
      // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-authelia" = validateAuthelia pkgs;
        "homelab/validate-systemd-authelia" = mkSystemdCheck host pkgs "homelab/validate-systemd-authelia" [
          "authelia-init.service"
          "authelia-default.service"
        ];
      };
    };
}
