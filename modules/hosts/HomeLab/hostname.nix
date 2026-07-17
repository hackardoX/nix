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

      systemd.services.setup-iwd-wifi = {
        description = "Configure iwd WiFi PSK from 1Password secrets";
        wantedBy = [ "multi-user.target" ];
        after = [ "opnix-secrets.service" ];
        wants = [ "opnix-secrets.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = lib.concatMapStringsSep "\n" (n: ''
          secret_path="${nixosArgs.config.services.onepassword-secrets.secretPaths.${n.secretName}}"
          psk_file="/var/lib/iwd/${n.ssid}.psk"

          if [ ! -f "$secret_path" ]; then
            echo "WiFi secret not available (no internet during boot?). Skipping iwd PSK setup for ${n.ssid}."
            exit 0
          fi

          new_pass=$(cat "$secret_path")
          current_pass=$(grep -oP '^Passphrase=\K.*' "$psk_file" 2>/dev/null || true)

          if [ "$current_pass" = "$new_pass" ]; then
            echo "WiFi password for ${n.ssid} is unchanged."
            exit 0
          fi

          install -Dm600 /dev/null "$psk_file"
          cat > "$psk_file" << EOF
          [Security]
          Passphrase=$new_pass
          EOF

          echo "WiFi PSK for ${n.ssid} updated, restarting iwd..."
          systemctl restart iwd
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
