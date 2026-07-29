{
  configurations.nixos.Hetzner-HomeLab = {
    deploy = {
      hostname = "hetzner-homelab";
      remoteBuild = true;
      interactiveSudo = true;
      user = "root";
    };
  };
}
