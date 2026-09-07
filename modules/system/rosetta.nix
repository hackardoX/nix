{
  flake.modules.darwin.base = {
    system.activationScripts.postActivation.text = /* Bash */ ''
      if [ ! -f /usr/libexec/rosetta/runtime ]; then
        echo "Installing Rosetta..."
        softwareupdate --install-rosetta --agree-to-license
      else
        echo "Rosetta is already installed"
      fi
    '';
  };
}
