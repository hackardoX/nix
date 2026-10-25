let
  documentationSettings = {
    doc.enable = false;
    info.enable = false;
    man.enable = true;
  };
in
{
  # https://mastodon.online/@nomeata/109915786344697931
  flake.modules.nixos.nix.documentation = documentationSettings;
  flake.modules.darwin.nix.documentation = documentationSettings;
}
