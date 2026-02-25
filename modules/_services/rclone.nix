{
  lib,
  ...
}:
{
  flake.modules.nixos.homelab =
    nixosArgs@{ pkgs, ... }:
    let
      cfg = nixosArgs.config.services.rclone-s3;

      instanceOptions = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "this rclone S3 instance" // {
            default = true;
          };

          remote = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Name of the rclone remote to use. If null, dataDir must be a local path.
              This will be used to reference the remote defined in remoteConfig.
            '';
            example = "koofr";
          };

          remoteConfig = lib.mkOption {
            type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
            default = null;
            description = ''
              Configuration for the rclone remote. This will create a section in rclone.conf.
              Only needed if remote is set.
              Note: Sensitive values should not be put here directly. Use environment variables instead.
            '';
            example = {
              type = "koofr";
              endpoint = "https://app.koofr.net";
            };
          };

          dataDir = lib.mkOption {
            type = lib.types.str;
            description = ''
              Directory or path to serve via S3.
              - If remote is set: path relative to remote (e.g., "/" or "/folder")
              - If remote is null: absolute local path (e.g., "/var/lib/<my-service>")
              Can use environment variables like $KOOFR_BASE_PATH
            '';
            example = "/var/lib/<my-service>";
          };

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1:8080";
            example = "0.0.0.0:8080";
            description = "Address and port to listen on.";
          };

          environmentFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "/run/secrets/rclone-env";
            description = ''
              Path to file containing environment variables for this instance.
              This file can contain:
              - S3_ACCESS_KEY_ID and S3_SECRET_ACCESS_KEY for S3 authentication (optional)
              - RCLONE_CONFIG_<REMOTE>_<OPTION> for remote configuration
              - Any other variables used in dataDir
            '';
          };

          enableAuth = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Whether to enable S3 authentication using S3_ACCESS_KEY_ID and S3_SECRET_ACCESS_KEY
              from the environment file. Set to false if you don't want authentication.
            '';
          };

          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [
              "--read-only"
              "--no-checksum"
            ];
            description = "Extra arguments to pass to rclone serve s3.";
          };

          user = lib.mkOption {
            type = lib.types.str;
            default = "rclone-s3";
            description = "User account under which rclone runs.";
          };

          group = lib.mkOption {
            type = lib.types.str;
            default = "rclone-s3";
            description = "Group under which rclone runs.";
          };
        };
      };

      enabledInstances = lib.filterAttrs (name: inst: name != "_module" && inst.enable or true) cfg;

      rcloneConfigContent = lib.concatStringsSep "\n\n" (
        lib.mapAttrsToList (
          _: instanceCfg:
          lib.optionalString (instanceCfg.remote != null && instanceCfg.remoteConfig != null) ''
            [${instanceCfg.remote}]
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = ${v}") instanceCfg.remoteConfig)}
          ''
        ) enabledInstances
      );

      getServePath =
        instanceCfg:
        if instanceCfg.remote != null then
          "${instanceCfg.remote}:${instanceCfg.dataDir}"
        else
          instanceCfg.dataDir;

      isLocalPath =
        instanceCfg:
        instanceCfg.remote == null
        && lib.hasPrefix "/" instanceCfg.dataDir
        && !(lib.hasInfix "$" instanceCfg.dataDir);

      mkService =
        name: instanceCfg:
        lib.nameValuePair "rclone-s3-${name}" {
          description = "Rclone S3 Server (${name})";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";

            ExecStartPre = lib.mkIf (isLocalPath instanceCfg) (
              pkgs.writeShellScript "rclone-s3-${name}-pre" ''
                mkdir -p ${instanceCfg.dataDir}
                chown ${instanceCfg.user}:${instanceCfg.group} ${instanceCfg.dataDir}
                chmod 0750 ${instanceCfg.dataDir}
              ''
            );

            ExecStart = ''
              ${lib.getExe pkgs.rclone}/bin/rclone serve s3 \
                ${lib.optionalString instanceCfg.enableAuth "--auth-key $${S3_ACCESS_KEY_ID},$${S3_SECRET_ACCESS_KEY}"} \
                --addr ${instanceCfg.listenAddress} \
                ${lib.concatStringsSep " " instanceCfg.extraArgs} \
                ${getServePath instanceCfg}
            '';

            EnvironmentFile = lib.mkIf (instanceCfg.environmentFile != null) instanceCfg.environmentFile;

            Restart = "on-failure";
            RestartSec = "5s";

            User = instanceCfg.user;
            Group = instanceCfg.group;

            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = lib.optional (isLocalPath instanceCfg) instanceCfg.dataDir;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            RestrictNamespaces = true;
            LockPersonality = true;
            RestrictRealtime = true;
            PrivateDevices = true;
            ProtectClock = true;
            SystemCallArchitectures = "native";

            LimitNOFILE = 65536;
            MemoryMax = "2G";
            TasksMax = 512;
          };
        };

      allUsers = lib.unique (lib.mapAttrsToList (_: inst: inst.user) enabledInstances);
      allGroups = lib.unique (lib.mapAttrsToList (_: inst: inst.group) enabledInstances);

    in
    {
      options.services.rclone-s3 = lib.mkOption {
        type = lib.types.attrsOf instanceOptions;
        default = { };
        description = "Rclone S3 server instances to run.";
        example = lib.literalExpression ''
          {
            koofr = {
              remote = "koofr";
              remoteConfig = {
                type = "koofr";
                endpoint = "https://app.koofr.net";
              };
              dataDir = "$KOOFR_BASE_PATH";
              listenAddress = "0.0.0.0:3200";
              environmentFile = "/run/secrets/rclone-koofr-env";
            };
          }
        '';
      };

      config = lib.mkIf (enabledInstances != { }) {
        environment.etc."rclone/rclone.conf" = lib.mkIf (rcloneConfigContent != "") {
          text = rcloneConfigContent;
          mode = "0644";
        };

        systemd.services = lib.mapAttrs' mkService enabledInstances;

        users.users = lib.genAttrs (lib.filter (u: u == "rclone-s3") allUsers) (_: {
          isSystemUser = true;
          group = "rclone-s3";
          description = "Rclone S3 service user";
        });

        users.groups = lib.genAttrs (lib.filter (g: g == "rclone-s3") allGroups) (_: { });
      };
    };
}
