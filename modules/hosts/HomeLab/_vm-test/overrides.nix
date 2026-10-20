# Test-only overrides applied on top of the real HomeLab-CI module in the VM
# check. Nothing here is imported by production. `host` is the evaluated
# HomeLab-CI config and is only read for names (secrets, users, containers).
{
  lib,
  pkgs,
  host,
  testedUsers,
}:
let
  inherit (lib) mkForce mkVMOverride;
  stub = import ./stub-image.nix { inherit pkgs; };

  # Service users that own podman containers, with the container names.
  containersByUser = lib.filterAttrs (_: names: names != [ ]) (
    lib.mapAttrs (_: h: lib.attrNames (h.services.podman.containers or { })) host.home-manager.users
  );
  stubContainer = {
    image = mkForce "docker-archive:${stub}";
    entrypoint = mkForce "/stub";
    extraConfig.Container.HealthCmd = mkForce "none";
  };

  # Lingering users of the real host, except the tested users whose podman units
  # script.sh waits for. Without linger their user managers stay down at boot.
  keepLinger = testedUsers;
  # linger defaults to null (unset), so test for null before the value.
  lingerUsers = lib.attrNames (lib.filterAttrs (_: u: u.linger != null && u.linger) host.users.users);
in
{
  imports = [ (import ./dummy-sops.nix { inherit lib pkgs host; }) ];

  virtualisation = {
    memorySize = 4096;
    cores = 4;
    diskSize = 4096;
    # Impermanence's /persist mount is part of `fileSystems`, which qemu-vm
    # replaces with its own; re-declare it as tmpfs so bind mounts still work.
    fileSystems."/persist" = {
      device = "tmpfs";
      fsType = "tmpfs";
      neededForBoot = true;
    };
  };

  # No btrfs root to roll back and no LUKS/swap/initrd SSH in the VM.
  boot.initrd = {
    luks.devices = mkVMOverride { };
    secrets = mkVMOverride { };
    network.enable = mkForce false;
    systemd.services.rollback.enable = mkForce false;
  };
  swapDevices = mkVMOverride [ ];

  # The SMTP startup check dials smtp.resend.com, which the VM cannot reach.
  services.authelia.instances.default.settings.notifier.disable_startup_check = true;

  # Off to keep the boot short. None of these is checked by script.sh.
  services = {
    # The dummy tunnel credentials are not JSON, so cloudflared would restart in
    # a loop. The sops secret itself is declared outside the enable switch
    # (modules/homelab/cloudflare-tunnel/default.nix), so script.sh still sees it.
    cloudflared.enable = mkForce false;
    # networking.nix sets avahi.enable without mkDefault, so mkForce is needed.
    avahi.enable = mkForce false;
  };
  systemd.services = {
    # Auto-initializes over the network (remote repos), so it can outlast the test.
    backrest.enable = mkForce false;
    # No real network in the VM; the wait only delays network-online.target.
    NetworkManager-wait-online.enable = mkForce false;
    # Test-only diagnostics: dumps the boot state after four minutes, so a dead
    # backdoor still leaves data in the CI log (the journal is forwarded to the
    # serial console, see test-instrumentation.nix). Type = simple and
    # DefaultDependencies = false keep it from delaying multi-user.target.
    homelab-vm-diagnostics = {
      description = "Test-only: dump boot state after four minutes";
      wantedBy = [ "multi-user.target" ];
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "simple";
        RemainAfterExit = false;
        # dev-ttyAMA0 is the aarch64 serial device (qemu-common.nix); this check is aarch64-only.
        ExecStart = pkgs.writeShellScript "homelab-vm-diagnostics" ''
          ${pkgs.coreutils}/bin/sleep 240
          ${pkgs.systemd}/bin/systemctl list-jobs --no-pager || true
          ${pkgs.systemd}/bin/systemctl status backdoor.service dev-hvc0.device dev-ttyAMA0.device --no-pager || true
        '';
      };
    };
  };

  users.users = lib.genAttrs (lib.subtractLists keepLinger lingerUsers) (_: {
    linger = mkForce false;
  });

  home-manager.users = lib.mapAttrs (_: names: {
    services.podman.containers = lib.genAttrs names (_: stubContainer);
  }) containersByUser;
}
