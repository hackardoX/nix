{ user }:
let
  _1password = "\"/Users/${user}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
in
{
  ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        forwardAgent = false;
        identitiesOnly = true;
        identityFile = "/Users/${user}/.ssh/github_personal.pub";
        extraOptions = {
          IdentityAgent = _1password;
          preferredAuthentications = "publickey";
        };
      };
    };
    forwardAgent = true;
    serverAliveInterval = 60;
    controlMaster = "auto";
    controlPersist = "30m";
  };
}
