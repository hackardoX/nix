# Authelia — Adding users and OIDC clients

## Add a new user

1. Generate the password hash:

   ```bash
   docker run --rm -it authelia/authelia:latest authelia hash-password
   ```

   Type the user's password when prompted. Copy the Argon2id hash line (starts with `$argon2id$...`).

2. Store the hash in 1Password:

   ```bash
   op item create --category password --title "Authelia <Username> Password Hash" \
     credential="<hash>" --vault Homelab
   ```

3. Declare the opnix secret in `modules/security/authelia.nix` (in the `onepassword-secrets.secrets` block):

   ```nix
   authelia<Username>PasswordHash = {
     path = "/run/secrets/authelia/<username>_password_hash";
     reference = "op://Homelab/Authelia/<Username> Password Hash/credential";
     owner = "authelia";
     group = "authelia";
   };
   ```

4. Add the user to the `autheliaUsers` let binding at the top of `modules/security/authelia.nix`:

   ```nix
   autheliaUsers = {
     hal = { ... };  # existing user
     <username> = {
       displayname = "<Display Name>";
       email = "<email>";
       passwordHashFile = "/run/secrets/authelia/<username>_password_hash";
     };
   };
   ```

5. Rebuild.

## Add an OIDC client

1. Generate the client secret:

   ```bash
   result=$(docker run --rm authelia/authelia:latest \
     authelia crypto hash generate pbkdf2 --variant sha512 --random --random.length 72 --random.charset rfc3986)
   hashed=$(echo "$result" | grep "Hashed" | sed 's/.* //')
   unhashed=$(echo "$result" | grep "Random" | sed 's/.* //')
   ```

2. Store the hashed secret (for Authelia) and the unhashed secret (for the app):

   ```bash
   op item create --category password --title "Authelia <App> OIDC Client Secret" \
     credential="$hashed" --vault Homelab
   op item create --category password --title "<App> OIDC Client Secret" \
     credential="$unhashed" --vault Homelab
   ```

3. Add the OIDC client entry to `flake.meta.oidc-clients` in `modules/homelab/security/authelia/default.nix`, keyed by the client id:
   ```nix
   <app> = {
     clientId = "<app>";
     clientName = "<Display Name>";
     policy = "one_factor";
     redirectUris = [ "https://<app-host>/oauth/callback" ];
     secretName = "authelia<App>OidcSecret";
   };
   ```
   `clientId` is also the entry key. The `secretName` must match an opnix secret declared in `modules/homelab/security/authelia/secrets.nix` (the hashed client secret). Optional per-client Authelia YAML overrides go in `extraYamlLines`.

4. Add the `oidcClientSecretFile` option to the app's homelab service module and wire it to a new opnix secret for the unhashed value.

5. Configure the app to use Authelia's OIDC (issuer URL: `https://auth.<domain>`, client ID from `config.flake.meta.oidc-clients.<app>.clientId`, client secret, scopes: `openid profile email`).

6. Rebuild.
