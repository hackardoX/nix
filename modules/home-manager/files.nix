{ user, lib }:
let
  publicEmail = "10788630+andrea11@users.noreply.github.com";
  sshPublicKeyFiles = [ "github_personal.pub" ];
in
{
  "Github/.gitconfig" = {
    text = builtins.import ./files/gitconfig.nix { inherit user; };
  };
  ".ssh/allowed_signers" = {
    text = lib.concatMapStrings (x: "${publicEmail} ${x}\n") (
      builtins.map (file: builtins.readFile (toString ./files + "/" + file)) sshPublicKeyFiles
    );
  };
}
// builtins.listToAttrs (
  map (file: {
    name = ".ssh/${file}";
    value = {
      text = builtins.readFile ./files/${file};
    };
  }) sshPublicKeyFiles
)
