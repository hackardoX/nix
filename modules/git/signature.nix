{ config, lib, ... }:
{
  flake.modules.homeManager.dev =
    hmArgs@{ pkgs, ... }:
    {
      programs.git = {
        hooks = {
          prepare-commit-msg = lib.getExe (
            pkgs.writeShellScriptBin "prepare-commit-msg" ''
              echo "Signing off commit"
              ${lib.getExe hmArgs.config.programs.git.package} interpret-trailers --if-exists doNothing --trailer \
              "Signed-off-by: ${config.flake.meta.users.aaccardo.name} <${config.flake.meta.users.aaccardo.email}>" \
              --in-place "$1"
            ''
          );
        };
        signing = {
          key = "${hmArgs.config.home.homeDirectory}/.ssh/git_signature.pub";
          format = "ssh";
          signer = "${pkgs._1password-gui}/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          signByDefault = true;
        };
        settings = {
          gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        };
      };

      home.file.".ssh/allowed_signers".text = ''
        ${config.flake.meta.users.aaccardo.email} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAyKRwHBMjjaxAMSHCzIz1XL1czMLPseOa7/Pif+Og3H hackardo
      '';
    };
}
