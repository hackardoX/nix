# Example NixOS Configuration for# Example NixOS Configuration for Sure Finance

## EXAMPLE 1: Basic Local Setup (Simplest - Good for testing)

```nix
services.sure-finance = {
  enable = true;
  secretFile = /run/secrets/sure-secret-key;
};
```

Access at: http://127.0.0.1:3000
Creates local PostgreSQL 16 and Redis automatically

## EXAMPLE 2: Production with Built-in Nginx

```nix
services.sure-finance = {
    enable = true;
    nginx.enable = true;
    secretFile = /run/secrets/sure-secret-key;

   settings = {
     domain = "finance.example.com";
     assumeSSL = true;
     forceSSL = true;
   };
 };

# Only need to configure ACME and Firewall at the system level
security.acme = {
   acceptTerms = true;
   defaults.email = "admin@example.com";
 };

 networking.firewall.allowedTCPPorts = [ 80 443 ];
```

## EXAMPLE 3: External Infrastructure

```nix
   services.sure-finance = {
     enable = true;
     enableLocalDB = false;
     enableLocalRedis = false;
     secretFile = /run/secrets/sure-secret-key;

     settings = {
       database = {
         host = "db.example.com";
         name = "sure_production";
         user = "sure_app";
       };

       redis = {
         host = "redis.example.com";
       };
     };
   };
}
```
