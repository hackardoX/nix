{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  name = "default-icon";
  src = ./profile.jpg;

  dontUnpack = true;

  installPhase = # Bash
    ''
      cp $src $out
    '';

  passthru = {
    fileName = "profile.jpg";
  };
}
