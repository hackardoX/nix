{ config, lib, ... }:
{
  flake.modules.homeManager.dev =
    hmArgs@{ pkgs, ... }:
    let
      userGit = config.flake.meta.users.${hmArgs.config.home.username}.git;
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
          key = "${hmArgs.config.home.homeDirectory}/.ssh/git_signature.pub";
          format = "ssh";
          signByDefault = true;
        };
        settings = {
          gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        };
      };

      home.file.".ssh/allowed_signers".text = ''
        ${userGit.email} ${userGit.signingKey}
      '';
    };
}
