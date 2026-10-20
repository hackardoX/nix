# Test-only sops: every secret of the real host (NixOS and Home Manager) is
# re-pointed at a throwaway, sops-encrypted file built from dummy values.
# Only sopsFile is overridden; owner, group, mode, path and restartUnits keep
# their production values. The secrets files of the repository are never read.
{
  lib,
  pkgs,
  host,
}:
let
  # Only users that import the sops-nix Home Manager module have a `sops` option.
  hmUsersWithSops = lib.filterAttrs (_: h: h ? sops) host.home-manager.users;
  hmSecrets = lib.concatMap (u: lib.attrValues u.sops.secrets) (lib.attrValues hmUsersWithSops);
  allSecrets = lib.attrValues host.sops.secrets ++ hmSecrets;

  # Whole-file secrets (key = "") get their own file; the others are nested by key path.
  keys = lib.unique (lib.filter (k: k != "") (map (s: s.key) allSecrets));
  valueFor =
    k:
    if lib.hasSuffix "/hashed_password" k then "!" else "dummy-${lib.replaceStrings [ "/" ] [ "-" ] k}";
  secretsTree = lib.foldl' (
    acc: k: lib.recursiveUpdate acc (lib.setAttrByPath (lib.splitString "/" k) (valueFor k))
  ) { } keys;
  secretsTemplate = pkgs.writeText "secrets.json" (builtins.toJSON secretsTree);
  usersTemplate = pkgs.writeText "users.json" (
    builtins.toJSON {
      users.dummy = {
        disabled = false;
        displayname = "Dummy";
        password = "placeholder";
        email = "dummy@example.invalid";
        groups = [ ];
      };
    }
  );

  dummy =
    pkgs.runCommand "homelab-vm-dummy-sops"
      {
        nativeBuildInputs = [
          pkgs.age
          pkgs.jq
          pkgs.openssh
          pkgs.openssl
          pkgs.sops
          pkgs.yq-go
        ];
      }
      ''
        set -euo pipefail
        mkdir -p $out
        age-keygen -o $out/key.txt >/dev/null 2>&1
        recipient=$(age-keygen -y $out/key.txt)

        # Values that must have a real format: Authelia's OIDC issuer key (RSA)
        # and the Beszel SSH keypair.
        openssl genrsa -out jwks.pem 2048 2>/dev/null
        ssh-keygen -q -t ed25519 -N "" -C homelab-vm -f beszel_ed25519

        hash=$(openssl passwd -6 dummy)
        jq --arg h "$hash" '.users.dummy.password = $h' ${usersTemplate} | yq -o=yaml . > users.yaml
        jq --rawfile jwks jwks.pem --rawfile priv beszel_ed25519 --rawfile pub beszel_ed25519.pub \
          '.authelia.jwks_key = $jwks | .beszel.ssh_private_key = $priv | .beszel.ssh_public_key = $pub' \
          ${secretsTemplate} | yq -o=yaml . > secrets.yaml

        sops --encrypt --age "$recipient" --input-type yaml --output-type yaml users.yaml > $out/users.yaml
        sops --encrypt --age "$recipient" --input-type yaml --output-type yaml secrets.yaml > $out/secrets.yaml
      '';

  # sops-nix rejects store paths for age.keyFile, so the throwaway key is copied to /run.
  keyFile = "/run/homelab-vm/age-key.txt";
  fileFor = s: if s.key == "" then "${dummy}/users.yaml" else "${dummy}/secrets.yaml";
  overrideSecrets = secrets: lib.mapAttrs (_: s: { sopsFile = lib.mkForce (fileFor s); }) secrets;
in
{
  sops = {
    defaultSopsFile = lib.mkForce "${dummy}/secrets.yaml";
    validateSopsFiles = false;
    age = {
      keyFile = lib.mkForce keyFile;
      sshKeyPaths = lib.mkForce [ ];
    };
    gnupg.sshKeyPaths = lib.mkForce [ ];
    secrets = overrideSecrets host.sops.secrets;
  };

  system.activationScripts = {
    homelabVmSopsKey = lib.stringAfter [ "specialfs" ] ''
      install -D -m 0444 ${dummy}/key.txt ${keyFile}
    '';
    setupSecrets.deps = [ "homelabVmSopsKey" ];
  };

  home-manager.users = lib.mapAttrs (_: h: {
    sops = {
      age.keyFile = lib.mkForce keyFile;
      validateSopsFiles = false;
      secrets = overrideSecrets h.sops.secrets;
    };
  }) hmUsersWithSops;
}
