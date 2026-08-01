{
  lib,
  ...
}:
let
  mkCryptRemoteName = jobName: provider: "${provider}-crypt-${jobName}";

  mkRcloneCryptRemote =
    jobName: jobCfg: provider:
    let
      destination = if jobCfg.destination != null then jobCfg.destination else jobName;
    in
    {
      config = {
        type = "crypt";
        remote = "${provider}:${destination}";
        filename_encryption = "standard";
        directory_name_encryption = "true";
      };
      secrets = {
        password = jobCfg.passwordFile;
      }
      // lib.optionalAttrs (jobCfg.saltFile != null) {
        password2 = jobCfg.saltFile;
      };
    };

  mkRcloneCryptRemotes =
    mkJobFn: jobs:
    lib.concatMapAttrs (
      jobName: jobCfg:
      lib.listToAttrs (
        map (provider: {
          name = mkCryptRemoteName jobName provider;
          value = mkJobFn jobName jobCfg provider;
        }) jobCfg.providers
      )
    ) (lib.filterAttrs (_: jobCfg: jobCfg.encrypted) jobs);
in
{
  flake.lib.rclone = {
    inherit mkCryptRemoteName mkRcloneCryptRemote mkRcloneCryptRemotes;
  };
}
