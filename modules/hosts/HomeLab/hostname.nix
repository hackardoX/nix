{ lib, ... }:
{
  configurations.nixos.HomeLab.module =
    nixosArgs:
    let
      wifiNetworks = [
        {
          ssid = "Livebox-0670_2GEXT";
          secretName = "wifiPassword";
          secretReference = "op://HomeLab/Wireless Router/wireless network password";
        }
      ];
    in
    {
      networking = {
        hostName = "HomeLab";
        wireless.iwd = {
          enable = true;
          settings.Settings.AutoConnect = true;
        };
      };

      systemd.services.iwd = {
        after = map (n: "onepassword-secrets-${n.secretName}.service") wifiNetworks;
        wants = map (n: "onepassword-secrets-${n.secretName}.service") wifiNetworks;
        preStart = lib.concatMapStringsSep "\n" (n: ''
          install -Dm600 /dev/null /var/lib/iwd/${n.ssid}.psk
          cat > /var/lib/iwd/${n.ssid}.psk << EOF
          [Security]
          Passphrase=$(cat ${nixosArgs.config.services.onepassword-secrets.secretPaths.${n.secretName}})
          [Settings]
          Autoconnect=true
          EOF
        '') wifiNetworks;
      };

      services.onepassword-secrets.secrets = builtins.listToAttrs (
        map (n: {
          name = n.secretName;
          value = {
            path = "/run/secrets/.${n.secretName}";
            reference = n.secretReference;
            group = "wheel";
          };
        }) wifiNetworks
      );
    };
}
