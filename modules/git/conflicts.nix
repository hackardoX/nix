{
  flake.modules.homeManager.dev = {
    programs = {
      git = {
        settings = {
          merge.conflictstyle = "zdiff3";
          rerere.enabled = true;
        };
      };
      mergiraf.enable = true;
    };
  };
}
