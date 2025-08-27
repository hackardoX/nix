{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    types
    ;
  inherit (lib.${namespace})
    mkOpt
    mkOptFlag
    ;
  inherit (inputs) home-manager;
  cfg = config.${namespace}.programs.containerization.docker;

  mkContextFlags =
    context:
    lib.concatStringsSep " " (
      lib.flatten [
        (lib.optional (context.name != null) context.name)
        (lib.optional (context.description != null) (mkOptFlag "description" "${context.description}"))
        (lib.optional (context.docker != null) (mkOptFlag "docker" "${context.docker}"))
      ]
    );

  configuredContexts = lib.concatMapStringsSep " " (context: context.name) cfg.contexts;
  defaultContexts = lib.filter (context: context.default) cfg.contexts;
  defaultContextName = if defaultContexts != [ ] then (lib.head defaultContexts).name else "default";
in
{
  options.${namespace}.programs.containerization.docker = {
    enable = mkEnableOption "docker";
    contexts =
      mkOpt
        (types.listOf (
          types.submodule {
            options = {
              name = mkOpt types.str "" "Name of the context.";
              description = mkOpt types.str "" "Description of the context.";
              docker = mkOpt types.str "" "Docker options.";
              default = mkOpt types.bool false "Set as default context.";
            };
          }
        ))
        [
          {
            name = "default";
          }
        ]
        "Docker contexts.";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (lib.length defaultContexts) <= 1;
        message = "More than one context defined as default";
      }
    ];

    home = {
      packages = with pkgs; [
        docker
      ];

      activation.docker-init = mkIf cfg.enable (
        home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          PATH=${pkgs.docker}/bin:$PATH

          echo "Managing Docker contexts..."

          # Get existing contexts (excluding 'default' which is built-in)
          EXISTING_CONTEXTS=$(${pkgs.docker}/bin/docker context ls -q 2>/dev/null | grep -v '^default$' || true)

          # Define configured contexts
          CONFIGURED_CONTEXTS="${configuredContexts}"

          # Create missing contexts
          ${lib.concatMapStringsSep "\n" (context: ''
            if ! echo "$EXISTING_CONTEXTS" | grep -q "^${context.name}$"; then
              echo "Creating context: ${context.name}"
              echo "Command: ${pkgs.docker}/bin/docker context create ${mkContextFlags context}"
              ${pkgs.docker}/bin/docker context create ${mkContextFlags context}
            else
              echo "Context ${context.name} already exists, skipping..."
            fi'') cfg.contexts}

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
          ${pkgs.docker}/bin/docker context use "${defaultContextName}"

          echo "Docker context management complete."
        ''
      );
    };
  };
}
