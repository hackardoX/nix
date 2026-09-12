{ inputs, lib, ... }:
{
  configurations.nixos.HomeLab.module =
    nixosArgs:
    let
      wifiNetworks = [
        {
          ssid = "Livebox-0670_2GEXT";
          secretName = "wifi/password";
        }
      ];
    in
    {
      networking = {
        hostName = "HomeLab";
        networkmanager = {
          enable = true;
          wifi.backend = "iwd";
        };
        firewall.allowedTCPPorts = [
          22
          80
          443
        ];
        useDHCP = lib.mkForce true;
        nameservers = lib.mkDefault [
          # Cloudflare DNS
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
          # Google DNS
          "8.8.8.8"
          "8.8.4.4"
          "2001:4860:4860::8888"
          "2001:4860:4860::8844"
        ];
      };

      services.avahi = {
        enable = true;
        publish = {
          enable = true;
          addresses = true;
          workstation = true;
        };
      };

      sops.secrets = builtins.listToAttrs (
        map (network: {
          name = network.secretName;
          value = {
            sopsFile = "${inputs.self}/secrets/hosts/HomeLab/secrets.yaml";
            group = "wheel";
          };
        }) wifiNetworks
      );

      systemd.services.setup-iwd-wifi = {
        description = "Configure iwd WiFi PSK from sops-nix secrets";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        # TODO: optimize this to iterate over the list instead of generating a script per network
        script = lib.concatMapStringsSep "\n" (n: ''
          secret_path="${nixosArgs.config.sops.secrets."${n.secretName}".path}"
          psk_file="/var/lib/iwd/${n.ssid}.psk"

          if [ ! -f "$secret_path" ]; then
            echo "WiFi secret not available. Skipping iwd PSK setup for ${n.ssid}."
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

          echo "WiFi PSK for ${n.ssid} updated. iwd will use it on next connection attempt."
        '') wifiNetworks;
      };
    };
}
