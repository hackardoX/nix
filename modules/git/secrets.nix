{
  flake.modules.homeManager.base = {
    programs.onepassword-secrets.secrets = {
      githubAuthorisation = {
        path = ".ssh/github_authorisation.pub";
        reference = "op://Development/Github Authorisation/public key";
        group = "staff";
      };
      gitSignature = {
        path = ".ssh/git_signature.pub";
        reference = "op://Development/Git Signature/public key";
        group = "staff";
      };
    };
  };
}
