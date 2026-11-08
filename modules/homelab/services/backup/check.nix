{ config, lib, ... }:
let
  host = config.flake.nixosConfigurations.HomeLab-CI.config;
  hmUsers = host.home-manager.users;
  inherit (config.flake.lib.checks) mkCheck mkSystemdCheck;
  backrestUser = "backrest";
  backupRepos = config.flake.meta.backup.repos;

  backupFailures =
    lib.concatLists (
      lib.mapAttrsToList (
        user: h:
        lib.concatLists (
          lib.mapAttrsToList (
            job: _:
            lib.optional (
              !lib.hasAttr job backupRepos
            ) "home-manager.users.${user}.services.backup.jobs.${job} has no flake.meta.backup.repos.${job}"
          ) (h.services.backup.jobs or { })
        )
      ) hmUsers
    )
    # --- append-only gateway -------------------------------------------------
    # The point of the gateway is that no service user holds the storage
    # credentials, and that each job's socket is reachable by its own group
    # only. Neither shows up as a failing unit, so check both.
    ++ lib.concatLists (
      lib.mapAttrsToList (
        user: h:
        lib.optional (
          (h.programs.rclone.remotes or { }) != { }
        ) "home-manager.users.${user} defines rclone remotes (${toString (lib.attrNames h.programs.rclone.remotes)}): it would hold storage credentials, use the backup gateway"
        ++ lib.concatLists (
          lib.mapAttrsToList (
            job: _:
            let
              socket = host.systemd.sockets."backup-gateway-${job}" or null;
              group = host.users.users.${user}.group;
            in
            if socket == null then
              [ "backup job ${job} (${user}) has no systemd.sockets.backup-gateway-${job}" ]
            else
              lib.optional (
                socket.socketConfig.SocketGroup != group
              ) "backup-gateway-${job} socket group is ${socket.socketConfig.SocketGroup}, expected ${group}"
              ++ lib.optional (
                socket.socketConfig.SocketMode != "0660"
              ) "backup-gateway-${job} socket mode is ${socket.socketConfig.SocketMode}, expected 0660"
              ++ lib.optional (
                !lib.elem group (host.users.users.${backrestUser}.extraGroups or [ ])
              ) "users.users.${backrestUser} is not in group ${group}, so Backrest cannot reach the ${job} socket"
          ) (h.services.backup.jobs or { })
        )
      ) hmUsers
    )
    ++ lib.concatLists (
      lib.mapAttrsToList (
        repo: r:
        lib.optional (
          r.uri != "rest:http+unix://${host.services.backup-gateway.socketDir}/${repo}.sock:/"
        ) "flake.meta.backup.repos.${repo}.uri is ${r.uri}, expected the ${host.services.backup-gateway.socketDir}/${repo}.sock gateway socket"
      ) backupRepos
    )
    ++ map (g: "users.users.${backrestUser}.extraGroups: group '${g}' is not defined in users.groups") (
      lib.filter (g: !lib.elem g (lib.attrNames host.users.groups)) (
        host.users.users.${backrestUser}.extraGroups or [ ]
      )
    );
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        "homelab/backup" = mkCheck pkgs "homelab/backup" backupFailures;
      }
      // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-linux") {
        "homelab/validate-systemd-backrest" = mkSystemdCheck host pkgs "homelab/validate-systemd-backrest" [
          "backrest.service"
        ];
        "homelab/validate-systemd-backup-gateway" =
          mkSystemdCheck host pkgs "homelab/validate-systemd-backup-gateway"
            (
              lib.concatMap
                (n: [
                  "${n}.service"
                  "${n}.socket"
                ])
                (lib.filter (n: lib.hasPrefix "backup-gateway-" n) (lib.attrNames host.systemd.sockets))
              ++ map (n: "${n}.service") (
                lib.filter (n: lib.hasPrefix "backup-prune-" n) (lib.attrNames host.systemd.services)
              )
              ++ map (n: "${n}.timer") (
                lib.filter (n: lib.hasPrefix "backup-prune-" n) (lib.attrNames host.systemd.timers)
              )
            );
      };
    };
}
