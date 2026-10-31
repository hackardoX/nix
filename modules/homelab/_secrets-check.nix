{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  hmUsers = host.home-manager.users;
  inherit (config.flake.lib.checks) mkCheck;
  backrestUser = "backrest";
  backupRepos = config.flake.meta.backup.repos;

  # --- sops-keys (checked by a runCommand, see below) ---------------------

  sopsSecrets = lib.mapAttrsToList (name: s: {
    inherit name;
    inherit (s) key format;
    file = s.sopsFile or host.sops.defaultSopsFile;
  }) host.sops.secrets;

  isChecked = s: (s.format == "yaml" || s.format == "json") && s.key != "";

  sopsNotes = lib.concatMap (
    s:
    if s.format != "yaml" && s.format != "json" then
      [ "sops.secrets.${s.name}: format '${s.format}' is not checked" ]
    else if s.key == "" then
      [ "sops.secrets.${s.name}: whole-file secret, not checked" ]
    else
      [ ]
  ) sopsSecrets;

  sopsFiles = lib.unique (map (s: s.file) (lib.filter isChecked sopsSecrets));

  sopsEntriesFor =
    file:
    map (s: {
      inherit (s) name key;
      path = lib.splitString "/" s.key;
    }) (lib.filter (s: isChecked s && s.file == file) sopsSecrets);

  sopsKeysCheck =
    pkgs:
    pkgs.runCommand "homelab-sops-keys"
      {
        nativeBuildInputs = [
          pkgs.yq-go
          pkgs.jq
        ];
      }
      ''
        fail=0

        # Only key names are read: sops keeps YAML/JSON keys in plaintext and
        # values stay encrypted. Nothing is decrypted and no values are printed.
        check_file() {
          file="$1"
          entries="$2"
          if ! json=$(yq -o=json '.' "$file"); then
            echo "  - $file: cannot be parsed" >&2
            fail=1
            return
          fi
          if ! missing=$(printf '%s' "$json" | jq -r --arg file "$file" --argjson entries "$entries" '. as $doc | $entries[] as $e | select((try ($doc | getpath($e.path)) catch null) == null) | "sops.secrets.\($e.name): key \"\($e.key)\" not found in \($file)"'); then
            echo "  - $file: could not be checked" >&2
            fail=1
            return
          fi
          if [ -n "$missing" ]; then
            printf '%s\n' "$missing" | sed 's/^/  - /' >&2
            fail=1
          fi
        }

        ${lib.concatMapStrings (n: "echo ${lib.escapeShellArg "note: ${n}"}\n") sopsNotes}
        ${lib.concatMapStrings (
          file:
          "check_file ${lib.escapeShellArg (toString file)} ${lib.escapeShellArg (builtins.toJSON (sopsEntriesFor file))}\n"
        ) sopsFiles}

        if [ "$fail" -ne 0 ]; then
          echo "homelab/sops-keys: failures above" >&2
          exit 1
        fi
        touch $out
      '';

  # --- secret-access -----------------------------------------------------

  secrets = lib.mapAttrsToList (name: s: {
    inherit name;
    inherit (s)
      path
      owner
      group
      mode
      ;
  }) host.sops.secrets;

  consumers =
    lib.concatLists (
      lib.mapAttrsToList (
        user: h:
        lib.concatLists [
          (lib.concatLists (
            lib.mapAttrsToList (
              container: c:
              lib.mapAttrsToList (env: path: {
                inherit user path;
                what = "container ${container} (${env})";
              }) (c.secrets or { })
            ) (h.services.podman.containers or { })
          ))
          (lib.concatLists (
            lib.mapAttrsToList (
              job: j:
              [
                {
                  inherit user;
                  what = "backup job ${job} encryptionKey";
                  path = j.encryptionKey;
                }
              ]
              ++ lib.optional (j.db != null && j.db.passwordFile != null) {
                inherit user;
                what = "backup job ${job} db.passwordFile";
                path = j.db.passwordFile;
              }
            ) (h.services.backup.jobs or { })
          ))
        ]
      ) hmUsers
    )
    ++ lib.mapAttrsToList (repo: r: {
      user = backrestUser;
      what = "backup repo ${repo} passwordFile";
      path = r.passwordFile;
    }) backupRepos;

  # Mode "0640" -> [ 0 6 4 0 ]. The owner, group and other read bits are the
  # digits >= 4.
  modeDigits = mode: map lib.toInt (lib.stringToCharacters (lib.fixedWidthString 4 "0" mode));

  canRead =
    user: s:
    let
      owner = if s.owner == null then "root" else s.owner;
      group = if s.group == null then "root" else s.group;
      digits = modeDigits s.mode;
      account = host.users.users.${user} or null;
      memberOf = lib.optionals (account != null) ([ account.group ] ++ account.extraGroups);
    in
    (owner == user && lib.elemAt digits 1 >= 4)
    || (lib.elem group memberOf && lib.elemAt digits 2 >= 4)
    || lib.elemAt digits 3 >= 4;

  secretFailures = lib.concatMap (
    c:
    let
      path = toString c.path;
      secret = lib.findFirst (s: toString s.path == path) null secrets;
    in
    if secret == null then
      lib.optional (lib.hasPrefix "/run/secrets/" path) "${c.user}: ${c.what} uses ${path}, which is not backed by any sops.secrets entry"
    else
      lib.optional (!canRead c.user secret)
        "${c.user}: ${c.what} reads sops secret '${secret.name}' but cannot (owner=${
          if secret.owner == null then "root" else secret.owner
        } group=${if secret.group == null then "root" else secret.group} mode=${secret.mode})"
  ) consumers;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        "homelab/sops-keys" = sopsKeysCheck pkgs;
        "homelab/secret-access" = mkCheck pkgs "homelab/secret-access" secretFailures;
      };
    };
}
