{ lib, ... }:
let
  # Ecosystem specs are auto-discovered from ./lua/providers: adding an
  # ecosystem means dropping a <name>.lua file there (then wiring its
  # filetypes through `post` and its packages into packagesByProvider).
  providerFiles = lib.mapAttrs' (
    name: _: lib.nameValuePair (lib.removeSuffix ".lua" name) ./lua/providers/${name}
  ) (lib.filterAttrs (_: type: type == "regular") (builtins.readDir ./lua/providers));

  # Formatter package names emitted by each provider's spec. autoInstall
  # only collects names from static formatters_by_ft lists, so dynamically
  # routed formatters must be installed explicitly. Note: this is let-bound
  # (not read back via config.flake.lib) because the deferred nixvim module
  # evaluates in the nixvim module system, where flake.* options are absent.
  packagesByProvider = {
    web = [
      "biome"
      "eslint_d"
      "oxfmt"
      "prettierd"
    ];
    python = [
      "ruff"
      "black"
    ];
  };
in
{
  flake.lib.formatRouting = {
    # Lua snippet assigning dynamic conform resolvers for `provider` to the
    # given filetypes. Assign through plugins.conform-nvim.luaConfig.post so
    # nixvim's autoInstall never sees the dynamically produced formatter
    # names; mkAfter lets several modules contribute to the same option.
    post =
      provider: filetypes:
      lib.mkAfter (
        lib.concatLines (
          map (
            ft:
            ''require("conform").formatters_by_ft.${ft} = require("dev.format_routing").resolver("${provider}", "${ft}")''
          ) filetypes
        )
      );

    # Formatter packages emitted by each provider's spec; see the let-bound
    # packagesByProvider above for why it isn't exposed through config.
    inherit packagesByProvider;
  };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraFiles = lib.mapAttrs' (target: source: lib.nameValuePair target { inherit source; }) (
        {
          "lua/dev/format_routing/init.lua" = ./lua/init.lua;
        }
        // lib.mapAttrs' (
          name: source: lib.nameValuePair "lua/dev/format_routing/providers/${name}.lua" source
        ) providerFiles
      );

      extraPackages = map (name: pkgs.${name}) (lib.flatten (builtins.attrValues packagesByProvider));
    };
}
