{
  flake.module.homeManager.homelab = {
    imports = [
      ./_sure-finance/default.nix
    ];
  };
}
