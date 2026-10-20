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
      assertions = [
        {
          assertion = lib.versionAtLeast hmArgs.config.programs.git.package.version "2.54";
          message = "Config-based Git hooks require git >= 2.54, but programs.git.package is ${hmArgs.config.programs.git.package.version}";
        }
      ];

      programs.git = {
        signing = {
          key = signatureKeyPath;
          format = "ssh";
          signByDefault = true;
        };
        settings = {
          gpg.ssh.allowedSignersFile = hmArgs.config.sops.templates."allowed_signers".path;
          # Config-based hook (git >= 2.54) so we do not set a global core.hooksPath,
          # which would break prek/pre-commit installs and bypass repo-managed hooks.
          hook.signoff = {
            event = "prepare-commit-msg";
            command = toString (
              pkgs.writeShellScript "signoff-hook" ''
                echo "Signing off commit"
                ${lib.getExe hmArgs.config.programs.git.package} interpret-trailers --if-exists doNothing --trailer \
                "Signed-off-by: $(git config user.name) <$(git config user.email)>" \
                --in-place "$1"
              ''
            );
          };
        };
      };

      sops.secrets."git/signing_key" = {
        path = signatureKeyPath;
        mode = "0644";
      };
      sops.templates."allowed_signers".content = ''
        ${hmArgs.config.sops.placeholder."github/email"} ${hmArgs.config.sops.placeholder."git/signing_key"}
        ${hmArgs.config.sops.placeholder."gitlab/email"} ${hmArgs.config.sops.placeholder."git/signing_key"}
      '';
    };
}
