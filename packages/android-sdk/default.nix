{
  inputs,
  pkgs,
  ...
}:
let
  # Check available architectures with nix flake show github:tadfisher/android-nixpkgs
  archMap = {
    x86_64 = "x86_64";
    aarch64 = "arm64-v8a";
  };
  android = {
    majorVersion = "35";
    architecture = archMap.${pkgs.stdenv.hostPlatform.parsed.cpu.name} or "x86_64";
  };
  base = inputs.android-nixpkgs.sdk.${pkgs.system} (
    sdkPkgs: with sdkPkgs; [
      sdkPkgs."build-tools-${android.majorVersion}-0-0"
      sdkPkgs.cmake-3-22-1
      cmdline-tools-latest
      emulator
      ndk-27-1-12297006
      platform-tools
      sdkPkgs."platforms-android-${android.majorVersion}"
      sdkPkgs."sources-android-${android.majorVersion}"
      sdkPkgs."system-images-android-${android.majorVersion}-google-apis-${android.architecture}"
    ]
  );
in
base.overrideAttrs (old: {
  pname = "android-sdk";
  version = android.majorVersion;
  passthru = (old.passthru or { }) // {
    inherit (android) architecture;
  };
})
