{ inputs, lib, ... }:
{
  flake.modules.nixos.hardening = nixosArgs: {
    imports = [
      inputs.nix-mineral.nixosModules.nix-mineral
    ];

    nix-mineral = {
      enable = true;
      preset = "compatibility";
    };

    services = {
      openssh = {
        settings = {
          MaxAuthTries = 3;
          LoginGraceTime = 30;
          MaxSessions = 3;
          ClientAliveInterval = 300;
          ClientAliveCountMax = 2;
          AllowTcpForwarding = false;
          UseDNS = false;
        };
        allowSFTP = true;
      };
    };

    nix.settings.allowed-users = lib.mkForce [ "root" ];

    environment.defaultPackages = lib.mkForce [ ];

    security = {
      auditd.enable = true;
      audit = {
        enable = true;
        rules = [
          "-a exit,always -F arch=b64 -S execve"
        ];
      };
    };
  };
}
