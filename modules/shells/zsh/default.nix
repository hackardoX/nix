let
  polyModule = {
    programs.zsh.enable = true;
  };
in
{
  flake.modules.nixos.base = polyModule;
  flake.modules.homeManager.base = polyModule;
}
