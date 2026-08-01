{
  flake.modules.homeManager.shell = {
    home = {
      shellAliases = {
        # Navigation shortcuts
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        "......" = "cd ../../../../..";
      };
    };
  };
}
