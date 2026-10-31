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
      };
    };
}
