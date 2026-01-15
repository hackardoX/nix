{
  flake.modules.nixvim.dev.globalOpts = {
    title = true;
    titlestring = "\ %{substitute(getcwd(),\ $HOME,\ '~',\ '''''')}";
  };
}
