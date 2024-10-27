{ user }:
let
  _1password = "\"/Users/${user}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
in
{
  ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        identitiesOnly = true;
        identityFile = [
          "/Users/${user}/.ssh/id_github"
        ];
        extraOptions = {
          IdentityAgent = _1password;
        };
      };
    };
  };
}
