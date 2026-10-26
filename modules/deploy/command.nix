{
  config,
  inputs,
  lib,
  ...
}:
{
  flake.modules.homeManager.shell =
    hmArgs@{
      pkgs,
      ...
    }:
    let
      aliases = lib.listToAttrs (
        map (node: lib.nameValuePair (lib.toLower node) node) (lib.attrNames config.flake.deploy.nodes)
      );

      aliasNames = lib.attrNames aliases;

      caseArms = lib.concatMapStringsSep "\n" (
        alias: "  ${alias}) node=${lib.escapeShellArg aliases.${alias}} ;;"
      ) aliasNames;

      deployRs = inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.deploy-rs;

      deployCommand = pkgs.writeShellApplication {
        name = "deploy";
        text = ''
          usage() {
            echo "usage: deploy <alias> [deploy-rs flags...]" >&2
            echo "aliases: ${lib.concatStringsSep ", " aliasNames}" >&2
          }

          if [ "$#" -eq 0 ]; then
            usage
            exit 1
          fi

          target="''${1,,}"
          shift

          case "$target" in
          ${caseArms}
            *)
              usage
              exit 1
              ;;
          esac

          exec ${lib.getExe deployRs} "${hmArgs.config.programs.nh.flake}#$node" "$@"
        '';
      };
    in
    {
      home.packages = [ deployCommand ];
    };
}
