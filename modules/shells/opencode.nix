{
  flake.modules.homeManager.dev = {
    programs.opencode = {
      enable = true;
      settings = {
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
