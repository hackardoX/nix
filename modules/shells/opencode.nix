{
  flake.modules.homeManager.dev = {
    programs.opencode = {
      enable = true;
      settings = {
        plugin = [ "opencode-claude-code-auth" ];
        autoupdate = false;
        permission = {
          "bash" = {
            "*" = "ask";
            "git *" = "allow";
            "npm *" = "allow";
            "ls *" = "allow";
            "cat *" = "allow";
            "grep *" = "allow";
            "rm *" = "deny";
          };
          edit = "ask";
        };
      };
    };
  };
}
