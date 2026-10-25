{
  flake.modules.homeManager.aliases = {
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
