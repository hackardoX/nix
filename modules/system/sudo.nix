{
  flake.modules.darwin.laptop.security = {
    pam.services = {
      sudo_local = {
        reattach = true;
        touchIdAuth = true;
      };
    };

    # Set sudo timeout to 30 minutes
    sudo.extraConfig = "Defaults    timestamp_timeout=30";
  };
}
