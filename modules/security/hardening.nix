{ inputs, lib, ... }:
{
  flake.modules.nixos.hardening = nixosArgs: {
    imports = [
      inputs.nix-mineral.nixosModules.nix-mineral
    ];

    # nix-mineral = {
    #   enable = true;
    #   preset = "compatibility";
    # };

    services = {
      openssh = {
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          MaxAuthTries = 3;
          LoginGraceTime = 30;
          MaxSessions = 3;
          ClientAliveInterval = 300;
          ClientAliveCountMax = 2;
          AllowTcpForwarding = false;
          AllowAgentForwarding = false;
          UseDNS = false;
        };
        allowSFTP = true;
      };

      crowdsec = {
        enable = true;
        enrollKeyFile = nixosArgs.config.services.onepassword-secrets.secretPaths.crowdsecEnrollKey;
        acquisitions = lib.mkIf nixosArgs.config.services.caddy.enable [
          {
            filenames = [ "/var/log/caddy/access.log" ];
            labels.type = "caddy";
          }
        ];
      };
      onepassword-secrets.secrets = {
        crowdsecEnrollKey = {
          path = "/run/secrets/crowdsec/enroll_key";
          reference = "op://Development/CrowdSec/enroll key";
          owner = "crowdsec";
          group = "crowdsec";
          services = [ "crowdsec" ];
        };
      };
    };

    nix.settings.allowed-users = [ "root" ];

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

  flake.modules.darwin.hardening = { };
}
