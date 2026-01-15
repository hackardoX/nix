{
  perSystem.pre-commit.settings.hooks.commitizen.enable = true;
  flake.modules.homeManager.shell =
    { config, pkgs, ... }:
    {
      programs.git.settings = {
        commit.template = "${config.home.homeDirectory}/.config/git/commit-template";
      };

      home = {
        file.".config/git/commit-template".text = ''

          # <type>(<scope>): <subject>
          # |<----  Using a Maximum Of 50 Characters  ---->|

          # Explain why this change is being made
          # |<----   Try To Limit Each Line to a Maximum Of 72 Characters   ---->|

          # Provide links or keys to any relevant tickets, articles or other resources
          # Example: Github issue #23

          # --- COMMIT END ---
          # Type can be:
          #   feat     (new feature)
          #   fix      (bug fix)
          #   refactor (refactoring production code)
          #   style    (formatting, missing semi colons, etc; no code change)
          #   docs     (changes to documentation)
          #   test     (adding or refactoring tests; no production code change)
          #   chore    (updating grunt tasks etc; no production code change)
          # --------------------
          # Scope is optional and can be anything specifying the place of the commit change
          # --------------------
          # Subject line should:
          #   - use imperative, present tense: "change" not "changed" nor "changes"
          #   - don't capitalize first letter
          #   - no dot (.) at the end
          # --------------------
          # Body should:
          #   - use imperative, present tense
          #   - include motivation for the change and contrast with previous behavior
          # --------------------
          # Footer should contain:
          #   - breaking changes (BREAKING CHANGE: <description>)
          #   - issues closed (Closes #123, #456)
          # --------------------
        '';
        packages = [ pkgs.commitizen ];
      };
    };
}
