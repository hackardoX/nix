{
  configurations.nixos.Hetzner-HomeLab.module = {
    sops.secrets = {
      "ssh/host_ed25519_key" = {
        group = "wheel";
      };
      "ssh/host_ed25519_key.pub" = {
        group = "wheel";
      };
    };
  };
}
