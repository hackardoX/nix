{
  configurations.nixos.HomeLab = {
    deploy = {
      hostname = "ssh.homelab4.fun";
      remoteBuild = true;
      user = "root";
    };
  };
}
