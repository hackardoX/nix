{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    ;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.services.openssh;
in
{
  options.${namespace}.services.openssh = with types; {
    enable = lib.mkEnableOption "OpenSSH support";
    authorizedKeys = mkOpt (listOf str) [ ] "The public keys to apply.";
    authorizedKeyFiles = mkOpt (listOf str) [ ] "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 22 "The port to listen on.";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      extraConfig = ''
        Port ${toString cfg.port}
        PasswordAuthentication no
        PermitRootLogin no
      '';
      # If it does not work, add ChallengeResponseAuthentication yes
    };

    users.users.${config.${namespace}.user.name}.openssh.authorizedKeys = {
      keys = cfg.authorizedKeys;
      keyFiles = cfg.authorizedKeyFiles;
    };
  };
}
