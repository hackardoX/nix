{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.${namespace}.security._1password;
in
{
  options.${namespace}.security._1password = {
    enable = mkEnableOption "1password";
    openv = mkEnableOption "openv";
  };

  config = mkIf cfg.enable {
    homebrew = {
      brews = mkIf cfg.openv [
        "hackardoX/homebrew-formulas/openv"
      ];

      casks = [
        "1password"
        "1password-cli"
      ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        "1Password for Safari" = 1569813296;
      };
    };

    ${namespace} = {
      home.extraOptions = {
        programs = mkIf cfg.openv {
          zsh.initContent = lib.mkAfter ''
            eval "$(/opt/homebrew/bin/openv hook zsh)"
          '';

          bash.initExtra = lib.mkAfter ''
            eval "$(/opt/homebrew/bin/openv hook bash)"
          '';

          fish.interactiveShellInit = lib.mkAfter ''
            /opt/homebrew/bin/openv hook fish | source
          '';
        };
      };
    };
  };
}
