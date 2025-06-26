{
  projectRootFile = "flake.nix";

  programs = {
    actionlint.enable = true;
    biome = {
      enable = true;
      settings.formatter.formatWithErrors = true;
    };
    clang-format.enable = true;
    deadnix = {
      enable = true;
    };
    fantomas.enable = true;
    gofmt.enable = true;
    isort.enable = true;
    nixfmt.enable = true;
    nufmt.enable = true;
    ruff-check.enable = true;
    ruff-format.enable = true;
    rustfmt.enable = true;
    shfmt = {
      enable = true;
      indent_size = 4;
    };
    statix.enable = true;
    # TODO: enable this if possible -> Maybe rust needed?
    taplo.enable = false;
    yamlfmt.enable = true;
  };

  settings = {
    global.excludes = [
      "*.editorconfig"
      "*.envrc"
      "*.gitconfig"
      "*.git-blame-ignore-revs"
      "*.gitignore"
      "*.gitattributes"
      "*.luacheckrc"
      "*CODEOWNERS"
      "*LICENSE"
      "*flake.lock"
      "*.conf"
      "*.gif"
      "*.ico"
      "*.ini"
      "*.micro"
      "*.png"
      "*.svg"
      "*.tmux"
      "*/config"
      # TODO: formatters?
      "*.ac"
      "*.css" # Exclude CSS files from formatting since we use Nix template variables
      "*.csproj"
      "*.fsproj"
      "*.in"
      "*.kdl"
      "*.kvconfig"
      "*.rasi"
      "*.sln"
      "*.xml"
      "*.zsh"
      "*Makefile"
      "*makefile"
    ];

    formatter.ruff-format.options = [ "--isolated" ];
  };
}
