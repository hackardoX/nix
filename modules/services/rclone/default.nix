{
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
      homebrew.casks = darwinArgs.lib.mkIf hasRcloneMounts [ "macfuse" ];
    };

  flake.modules.homeManager.base =
    hmArgs:
    let
      isResticEnabled = hmArgs.config.services.restic.enable;
      hasRcloneMounts = builtins.any (remote: remote.mounts or { } != { }) (
        builtins.attrValues hmArgs.config.programs.rclone.remotes
      );
    in
    {
      programs.rclone.enable = isResticEnabled || hasRcloneMounts;
    };
}
