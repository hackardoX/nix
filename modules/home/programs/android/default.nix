{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.programs.android;
in
{
  options.${namespace}.programs.android = {
    enable = lib.mkEnableOption "android-sdk";
  };

  config = lib.mkIf cfg.enable {
    home = {
      sessionVariables = {
        JAVA_HOME = pkgs.zulu.home;
        ANDROID_HOME = "${pkgs.${namespace}.android-sdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${pkgs.${namespace}.android-sdk}/share/android-sdk";
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=\${ANDROID_SDK_ROOT}/build-tools/${
          pkgs.${namespace}.android-sdk.version
        }.0.0/aapt2";
        ANDROID_AVD_HOME = "~/.config/.android/avd";
      };

      packages = with pkgs; [
        aapt
        pkgs.${namespace}.android-sdk
        zulu
      ];
    };
  };
}
