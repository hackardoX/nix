# NixOS Custom

## Usage

### Apply Command

This must be run once to set the username in the NixOS configuration.
To run the apply command, use the following command:

```bash
nix run .#apply
```

This will setup the correctly username in the NixOS configuration.

### Build Command

To run the build command, use the following command:

```bash
nix build .#build
```

This will create a NixOS system configuration in the `result` directory.

### Build Switch Command

To run the build switch command, use the following command:

```bash
nix run .#build-switch
```

This will switch the current NixOS system to the new configuration.

### Rollback Command

To rollback to the previous configuration, use the following command:

```bash
nix run .#rollback
```

This will revert the current NixOS system to the last known good configuration.
