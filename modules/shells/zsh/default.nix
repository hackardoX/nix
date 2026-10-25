let
  polyModule = {
    programs.zsh.enable = true;
  };
in
{
  flake.modules.nixos.zsh = polyModule;
  flake.modules.darwin.zsh = polyModule;
  flake.modules.homeManager.zsh = polyModule;
}
