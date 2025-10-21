{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.${namespace}) mkOpt enabled;
  inherit (config.${namespace}) user;

  cfg = config.${namespace}.programs.terminal.tools.jujutsu;
in
{
  options.${namespace}.programs.terminal.tools.jujutsu = {
    enable = mkEnableOption "jujutsu";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
    signingKey =
      mkOpt types.str "${config.home.homeDirectory}/.ssh/git_signature.pub"
        "The key ID to sign commits with.";
    user = {
      name = mkOpt types.str user.fullName "The name to configure jujutsu with.";
      email = mkOpt types.str user.email "The email to configure jujutsu with.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ lazyjj ];

    programs = {
      jujutsu = {
        enable = true;
        package = pkgs.jujutsu;

        settings = {
          inherit user;
          fetch = {
            prune = true;
          };
          init = {
            default_branch = "main";
          };
          lfs = enabled;
          push = {
            # autoSetupRemote = true;
            default = "current";
          };
          rebase = {
            auto_stash = true;
          };
        };
      };
    };
  };
}
