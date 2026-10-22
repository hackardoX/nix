# Test-only container image: a busybox that sleeps forever and ignores its
# arguments, so every quadlet can start without pulling anything from a registry.
{ pkgs }:
let
  stubScript = pkgs.writeScript "stub" ''
    #!/bin/sh
    trap 'exit 0' TERM
    while :; do sleep 3600 & wait $!; done
  '';
  stubRoot = pkgs.buildEnv {
    name = "homelab-stub-root";
    paths = [
      pkgs.busybox
      (pkgs.runCommand "homelab-stub-entrypoint" { } ''
        mkdir -p $out
        ln -s ${stubScript} $out/stub
      '')
    ];
  };
in
pkgs.dockerTools.buildImage {
  name = "homelab-stub";
  tag = "latest";
  copyToRoot = stubRoot;
  # Uncompressed, so `docker-archive:` can read it directly.
  compressor = "none";
  config.Entrypoint = [ "/stub" ];
}
