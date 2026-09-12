{
  lib,
  ...
}:
{
  flake.modules.homeManager.dev =
    hmArgs@{ pkgs, ... }:
    let
      signatureKeyPath = "${hmArgs.config.home.homeDirectory}/.ssh/git_signature.pub";
    in
    {
      programs.git = {
        hooks = {
          prepare-commit-msg = lib.getExe (
            pkgs.writeShellScriptBin "prepare-commit-msg" ''
              echo "Signing off commit"
              ${lib.getExe hmArgs.config.programs.git.package} interpret-trailers --if-exists doNothing --trailer \
              "Signed-off-by: $(git config user.name) <$(git config user.email)>" \
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
        ${hmArgs.config.sops.placeholder."github/email"} ${hmArgs.config.sops.placeholder."git/signing_key"}
        ${hmArgs.config.sops.placeholder."gitlab/email"} ${hmArgs.config.sops.placeholder."git/signing_key"}
      '';
    };
}
