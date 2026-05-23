{
  configurations.nixos.HomeLab.module = nixosArgs: {
    networking = {
      hostName = "HomeLab";
      networkmanager.wifi.backend = "wpa_supplicant";
      wireless.iwd = {
        enable = true;
        settings = {
          Network = {
            EnableIPv6 = true;
          };
          Settings = {
            AutoConnect = true;
          };
        };

      };
    };
    systemd.services.iwd.preStart =
      let
        wifiPasswordFile = nixosArgs.config.services.onepassword-secrets.secretPaths.wifiPassword;
        ssid = "";
      in
      ''
        install -Dm600 /dev/null /var/lib/iwd/${ssid}.psk
        printf '[Security]\nPassphrase=%s\n[Settings]\nAutoconnect=true\n' \
          "$(cat ${wifiPasswordFile})" > /var/lib/iwd/${ssid}.psk
      '';

    services.onepassword-secrets.secrets = {
      wifiPassword = {
        path = "/run/secrets/.wifi_password";
        reference = "op://Development/HomeLab/wifi password";
        group = "wheel";
      };
    };
  };
}
