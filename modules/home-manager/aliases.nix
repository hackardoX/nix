{
  flake.modules.homeManager.base = {
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
