{
  config,
  lib,
  ...
}:
{
  flake.modules.homeManager.dev =
    hmArgs@{ pkgs, ... }:
    let
      userGit = config.flake.meta.users.${hmArgs.config.home.username}.git;
      signatureKeyPath = "${hmArgs.config.home.homeDirectory}/.ssh/git_signature.pub";
    in
    {
      programs.git = {
        hooks = {
          prepare-commit-msg = lib.getExe (
            pkgs.writeShellScriptBin "prepare-commit-msg" ''
              echo "Signing off commit"
              ${lib.getExe hmArgs.config.programs.git.package} interpret-trailers --if-exists doNothing --trailer \
              "Signed-off-by: ${userGit.name} <${userGit.email}>" \
              --in-place "$1"
            ''
          );
        };
        signing = {
          key = signatureKeyPath;
          format = "ssh";
          signByDefault = true;
        };
        settings = {
          gpg.ssh.allowedSignersFile = hmArgs.config.sops.templates."allowed_signers".path;
        };
      };

      sops.secrets."git/signing_key" = {
        path = signatureKeyPath;
        mode = lib.mkDefault "0644";
      };
      sops.templates."allowed_signers".content = ''
        ${userGit.email} ${hmArgs.config.sops.placeholder."git/signing_key"}
      '';
    };
}
