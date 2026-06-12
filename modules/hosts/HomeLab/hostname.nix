{
  configurations.nixos.HomeLab.module = nixosArgs: {
    networking = {
      hostName = "HomeLab";
      networkmanager.wifi.backend = "iwd";
    };

    systemd.services.iwd.preStart =
      let
        wifiPasswordFile = nixosArgs.config.services.onepassword-secrets.secretPaths.wifiPassword;
        ssid = "Livebox-0670_2GEXT";
      in
      ''
        install -Dm600 /dev/null /var/lib/iwd/${ssid}.psk
        cat > /var/lib/iwd/${ssid}.psk << EOF
        [Security]
        Passphrase=$(cat ${wifiPasswordFile})
        [Settings]
        Autoconnect=true
        EOF
      '';

    services.onepassword-secrets.secrets = {
      wifiPassword = {
        path = "/run/secrets/.wifi_password";
        reference = "op://HomeLab/Wireless Router/wireless network password";
        group = "wheel";
      };
    };
  };
}
