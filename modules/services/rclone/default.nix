{ lib, ... }: {
  flake.modules.darwin.base =
    darwinArgs:
    let
      primaryUser = darwinArgs.config.system.primaryUser;
      hmConfig = darwinArgs.config.home-manager.users.${primaryUser};
      hasRcloneMounts = builtins.any (remote: remote.mounts or { } != { }) (
        builtins.attrValues hmConfig.programs.rclone.remotes
      );
    in
    {
      homebrew.casks = lib.mkIf hasRcloneMounts [ "macfuse" ];
    };
}
