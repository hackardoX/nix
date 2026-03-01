{
  flake.module.darwin.base = {
    system.activationScripts.postActivation.text = /* Bash */ ''
      echo "Installing Rosetta..."
      softwareupdate --install-rosetta --agree-to-license
    '';
  };
}
