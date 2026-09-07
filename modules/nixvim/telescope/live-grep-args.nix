########################################################################
# telescope-live-grep-args.nvim
#
# Adds an alternate `live_grep` picker (bound to <Leader>fg, see
# keymaps.nix) that lets you pass ad hoc ripgrep flags directly in the
# search prompt, on top of the global excludes already configured in
# ripgrep.nix (--hidden, !**/.git/*, !**/*.lock).
#
# Prompt syntax (typed live in the picker, applies to that search only):
#
#   foo                    search for "foo" (identical to plain live_grep)
#   -g '*.rs' foo          only search inside *.rs files
#   -g '!*.lock' foo       exclude *.lock files for this search
#   -g '!vendor/*' foo     exclude a folder for this search
#   -t rust foo            search only rust-typed files (rg --type)
#   --iglob '*.md' foo     case-insensitive glob match
#
# Notes:
#   - `auto_quoting = true` means a plain search term (e.g. "foo") is
#     treated as one literal argument, so multi-word searches work
#     without quoting. But it ALSO means the whole prompt only gets
#     split into separate rg arguments (flags + term) if the very
#     FIRST character of the prompt is ', " or -. Typing the term
#     first (`foo -g '*.rs'`) does NOT work: the entire string is sent
#     to rg as one literal pattern and matches nothing.
#   - To add flags after already typing a term, press <C-k> (insert
#     mode) to auto-quote what you've typed so far, then continue with
#     flags, e.g. type `foo`, press <C-k> -> `"foo" `, then type
#     `-g '*.rs'`. Alternatively just type the flag first as shown
#     above.
#   - Multiple flags can be combined, e.g. `-g '*.rs' -g '!test_*' foo`.
#   - <C-space> (insert mode) fuzzy-refines the current results, same
#     as vanilla live_grep's default mapping.
########################################################################
{
  flake.modules.nixvim.dev.plugins.telescope.extensions.live-grep-args = {
    enable = true;
    settings = {
      auto_quoting = true;
      mappings.i = {
        "<C-space>".__raw = ''require("telescope.actions").to_fuzzy_refine'';
        "<C-k>".__raw = ''require("telescope-live-grep-args.actions").quote_prompt()'';
      };
    };
  };
}
