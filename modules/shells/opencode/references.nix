{ lib, ... }:
{
  # Local clones the agents may consult as references. They are never cloned
  # or fetched; the sandbox only gets read access to the paths listed here.
  flake.modules.homeManager.aaccardo =
    let
      references = {
        nix = {
          path = "~/GitHub/nix";
          description = "Personal Nix flake: Home Manager, nix-darwin, OpenCode config.";
        };
        proton-clients = {
          path = "~/GitLab/proton/clients";
          description = "Proton web clients monorepo.";
        };
        proton-monorepo = {
          path = "~/GitLab/proton/monorepo";
          description = "Proton monorepo.";
        };
        proton-packages = {
          path = "~/GitLab/proton/packages";
          description = "Shared packages and libraries.";
        };
      };
    in
    {
      programs.opencode.settings.references = references;

      # The sandbox sees $HOME-expanded clones, read-only (see sandbox.nix).
      programs.opencode.sandbox.readPaths = lib.mapAttrsToList (
        _: ref: builtins.replaceStrings [ "~" ] [ "$HOME" ] ref.path
      ) references;
    };
}
