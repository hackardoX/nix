{
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.base =
    { config, pkgs, ... }:
    let
      mkContextFlags =
        context:
        lib.concatStringsSep " " (
          lib.flatten [
            context.name
            "--description=${context.description}"
            "--docker"
            "${context.docker}"
          ]
        );

      dockerContext = {
        name = "podman";
        description = "Context used to connect to podman socket";
        docker = "host=unix://${config.podman.currentSocket}";
        default = true;
      };
    in
    {
      home = {
        packages = with pkgs; [
          docker
        ];

        activation.docker-init = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
          inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            PATH=${pkgs.docker}/bin:$PATH

            echo "Managing Docker contexts..."

            # Get existing contexts (excluding 'default' which is built-in)
            EXISTING_CONTEXTS=$(${pkgs.docker}/bin/docker context ls -q 2>/dev/null | grep -v '^default$' || true)

            # Define configured contexts
            CONFIGURED_CONTEXTS="${dockerContext.name}"

            # Create missing contexts
            if ! echo "$EXISTING_CONTEXTS" | grep -q "^${dockerContext.name}$"; then
              echo "Creating context: ${dockerContext.name}"
              echo "Command: ${pkgs.docker}/bin/docker context create ${mkContextFlags dockerContext}"
              ${pkgs.docker}/bin/docker context create ${mkContextFlags dockerContext}
            else
              echo "Context ${dockerContext.name} already exists, skipping..."
            fi

            # Remove contexts that are not configured
            for existing in $EXISTING_CONTEXTS; do
              if [ -n "$existing" ]; then
                found=false
                for configured in $CONFIGURED_CONTEXTS; do
                  if [ "$existing" = "$configured" ]; then
                    found=true
                    break
                  fi
                done
                if [ "$found" = "false" ]; then
                  echo "Removing unconfigured context: $existing"
                  ${pkgs.docker}/bin/docker context rm "$existing" 2>/dev/null || echo "Failed to remove context $existing"
                fi
              fi
            done

            # Set default context
            ${pkgs.docker}/bin/docker context use "${dockerContext.name}"

            echo "Docker context management complete."
          ''
        );
      };
    };
}
