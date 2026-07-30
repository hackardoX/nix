{ config, ... }:

{
  flake.modules.nixos.homelab-ssh-watchdog = { pkgs, ... }: {
    systemd.services.ssh-watchdog = {
      description = "Check SSH availability and reboot if unresponsive";
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        set -euo pipefail

        # Safety guard: if sshd isn't enabled, do nothing.
        # This prevents accidental reboots on systems without SSH.
        if ! ${pkgs.systemd}/bin/systemctl is-enabled --quiet sshd 2>/dev/null; then
          exit 0
        fi

        # Check systemd unit state and TCP port 22
        if ! ${pkgs.systemd}/bin/systemctl is-active --quiet sshd || \
           ! ${pkgs.netcat-openbsd}/bin/nc -z -w 3 127.0.0.1 22; then
          echo "ssh-watchdog: SSH appears down, initiating reboot..."
          ${pkgs.systemd}/bin/systemctl reboot
        fi
      '';
    };

    systemd.timers.ssh-watchdog = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1h";
        Persistent = true;
        Unit = "ssh-watchdog.service";
      };
    };
  };
}
