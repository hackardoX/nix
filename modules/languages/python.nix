{ lib, config, ... }:
{
  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        basedpyright
        ruff
        # debugpy must live inside the interpreter: nvim-dap-python launches
        # `python -m debugpy.adapter` from whatever python3 is on PATH.
        (python3.withPackages (ps: [
          ps.debugpy
        ]))
        uv
      ];
      lsp.servers = {
        basedpyright.enable = true;
        ruff.enable = true;
      };

      plugins = {
        conform-nvim.luaConfig.post = config.flake.lib.formatRouting.post "python" [ "python" ];
        dap-python.enable = true;
      };
    };

  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        python3
        uv
      ];

      programs.opencode = {
        extraPackages = with pkgs; [
          basedpyright
          ruff
        ];
        settings.lsp = {
          basedpyright = {
            command = [
              (lib.getExe' pkgs.basedpyright "basedpyright-langserver")
              "--stdio"
            ];
            extensions = [
              ".py"
              ".pyi"
              ".pyw"
            ];
          };

          ruff = {
            command = [
              (lib.getExe pkgs.ruff)
              "server"
            ];
            extensions = [
              ".py"
              ".pyi"
              ".pyw"
            ];
          };
        };
      };
    };
}
