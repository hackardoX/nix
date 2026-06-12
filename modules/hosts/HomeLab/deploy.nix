{
  configurations.nixos.HomeLab = {
    deploy = {
      hostname = "HomeLab";
      remoteBuild = true;
      interactiveSudo = true;
      user = "hal";
    };
  };
}
