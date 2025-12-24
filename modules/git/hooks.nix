{ inputs, ... }:
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem = {
    pre-commit.check.enable = true;
  };
}
