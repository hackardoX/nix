{
  flake.modules.homeManager.base = {
    home.file = {
      ".ssh/github_authorisation.pub".text = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsOzI1TFwbRy/GgE2/fNJR8B7gfIogp//2kDJ7D1uSB hackardoX@github.com
      '';
      ".ssh/git_signature.pub".text = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAyKRwHBMjjaxAMSHCzIz1XL1czMLPseOa7/Pif+Og3H hackardoX@git
      '';
    };
  };
}
