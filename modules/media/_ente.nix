{
  flake.modules.nixos.homelab =
    nixosArgs:
    let
      domain = "";
    in
    {
      services = {
        ente = {
          web = {
            enable = true;
            domains = {
              accounts = "accounts.${domain}";
              albums = "albums.${domain}";
              cast = "cast.${domain}";
              photos = "photos.${domain}";
            };
          };
          api = {
            enable = true;
            nginx.enable = true;
            enableLocalDB = true;
            domain = "api.${domain}";
            settings = {
              s3 = {
                use_path_style_urls = true;
                b2-eu-cen = {
                  endpoint = "localhost:3200";
                  region = "us-east-1";
                  bucket = "ente";
                  key._secret = nixosArgs.config.services.onepassword-secrets.secretPaths.enteS3AccessKey;
                  secret._secret = nixosArgs.config.services.onepassword-secrets.secretPaths.enteS3SecretKey;
                };
              };
              key = {
                encryption._secret = nixosArgs.config.services.onepassword-secrets.secretPaths.enteEncryptionKey;
                hash._secret = nixosArgs.config.services.onepassword-secrets.secretPaths.enteHashKey;
              };
              jwt.secret._secret = nixosArgs.config.services.onepassword-secrets.secretPaths.enteJwtSecret;
              credentials-dir = dirOf nixosArgs.config.services.onepassword-secrets.secretPaths.enteFirebaseCredentials;
            };
          };
        };

        nginx = {
          recommendedProxySettings = true;
          virtualHosts."accounts.${domain}".enableACME = true;
          virtualHosts."albums.${domain}".enableACME = true;
          virtualHosts."api.${domain}".enableACME = true;
          virtualHosts."cast.${domain}".enableACME = true;
          virtualHosts."photos.${domain}".enableACME = true;
        };

        rclone-s3.koofr = {
          remote = "koofr";
          remoteConfig = {
            type = "koofr";
            endpoint = "https://app.koofr.net";
          };
          dataDir = "/ente";
          listenAddress = "0.0.0.0:3201";
          environmentFile = nixosArgs.config.services.onepassword-secrets.secretPaths.rcloneKoofrEnv;
        };

        onepassword-secrets.secrets = {
          enteS3SecretKey = {
            path = "/etc/.secrets/ente/koofr_secret_key";
            reference = "op://Development/Ente HomeLab/s3 koofr secret key";
            owner = "ente";
            group = "ente";
            services = [ "ente" ];
          };
          enteS3AccessKey = {
            path = "/etc/.secrets/ente/koofr_access_key";
            reference = "op://Development/Ente HomeLab/s3 koofr access key";
            owner = "ente";
            group = "ente";
            services = [ "ente" ];
          };
          enteKoofrPassword = {
            path = "/etc/.secrets/ente/koofr_password";
            reference = "op://Development/Ente HomeLab/koofr password";
            owner = "ente";
            group = "ente";
            services = [ "ente" ];
          };
          enteEncryptionKey = {
            path = "/etc/.secrets/ente/encryption_key";
            reference = "op://Development/Ente HomeLab/encryption key";
            owner = "ente";
            group = "ente";
            services = [ "ente" ];
          };
          enteHashKey = {
            path = "/etc/.secrets/ente/hash_key";
            reference = "op://Development/Ente HomeLab/hash key";
            owner = "ente";
            group = "ente";
            services = [ "ente" ];
          };
          enteJwtSecret = {
            path = "/etc/.secrets/ente/jwt_secret";
            reference = "op://Development/Ente HomeLab/jwt secret";
            owner = "ente";
            group = "ente";
            services = [ "ente" ];
          };
          enteFirebaseCredentials = {
            path = "/etc/.secrets/ente/fcm-service-account.json";
            reference = "op://Development/Ente HomeLab/firebase service account";
            owner = "ente";
            group = "ente";
            services = [ "ente" ];
          };
          rcloneKoofrEnv = {
            path = "/etc/.secrets/ente/koofr_credentials.env";
            reference = "op://Development/Rclone HomeLab/koofr credentials";
            owner = "rclone-s3";
            group = "rclone-s3";
            services = [ "rclone-s3" ];
          };
        };
      };
      networking.firewall.allowedTCPPorts = [
        443
      ];
    };
}
