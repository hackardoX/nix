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
        networkmanager.wifi.backend = "iwd";
      };

      systemd.services.iwd = {
        after = map (network: "onepassword-secrets-${network.secretName}.service") wifiNetworks;
        wants = map (network: "onepassword-secrets-${network.secretName}.service") wifiNetworks;
        preStart = lib.concatMapStringsSep "\n" (n: ''
          psk_file=/var/lib/iwd/${n.ssid}.psk
          new_pass=$(cat ${nixosArgs.config.services.onepassword-secrets.secretPaths.${n.secretName}})
          current_pass=$(grep -oP '^Passphrase=\K.*' "$psk_file" 2>/dev/null || true)

          if [ "$current_pass" = "$new_pass" ]; then
            exit 0
          fi

          install -Dm600 /dev/null /var/lib/iwd/${n.ssid}.psk
          cat > /var/lib/iwd/${n.ssid}.psk << EOF
          [Security]
          Passphrase=$(cat ${nixosArgs.config.services.onepassword-secrets.secretPaths.${n.secretName}})
          EOF
        '') wifiNetworks;
      };

      services.onepassword-secrets.secrets = builtins.listToAttrs (
        map (network: {
          name = network.secretName;
          value = {
            path = "/run/secrets/.${network.secretName}";
            reference = network.secretReference;
            group = "wheel";
          };
        }) wifiNetworks
      );
    };
}
