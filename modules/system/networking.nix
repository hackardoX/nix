{
  flake.modules.darwin.base = {
    networking = {
      dns = [
        # Cloudflare DNS
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
        # Google DNS
        "8.8.8.8"
        "8.8.4.4"
        "2001:4860:4860::8888"
        "2001:4860:4860::8844"
      ];
      applicationFirewall = {
        enableStealthMode = true;
        blockAllIncoming = true;
      };
    };
  };
}
