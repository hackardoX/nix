{ lib, config, ... }:
let
  jsFiletypes = [
    "typescript"
    "javascript"
    "javascriptreact"
    "typescriptreact"
  ];
in
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nodejs
      ];

      programs.opencode = {
        extraPackages = with pkgs; [
          typescript
        ];
        settings.lsp = {
          typescript = {
            command = [
              (lib.getExe pkgs.typescript)
              "--lsp"
              "--stdio"
            ];
            extensions = [
              ".ts"
              ".tsx"
              ".js"
              ".jsx"
              ".mjs"
              ".cjs"
              ".mts"
              ".cts"
            ];
          };
        };
      };
    };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      plugins = {
        conform-nvim.luaConfig.post = config.flake.lib.formatRouting.post "web" jsFiletypes;
        dap = {
          luaConfig.post = ''
            -- Walk up from dir looking for <pkg_file>; returns root, path or nil
            function _dap_find_pkg(dir, pkg_file)
              while dir ~= "" and dir ~= "/" do
                local candidate = dir .. "/" .. pkg_file
                if vim.uv.fs_stat(candidate) then
                  return dir, candidate
                end
                dir = vim.fn.fnamemodify(dir, ":h")
              end
              return nil
            end
          '';
          adapters.servers.pwa-node = {
            host = "localhost";
            port = "\${port}";
            executable = {
              command = lib.getExe pkgs.vscode-js-debug;
              args = [ "\${port}" ];
            };
          };
          configurations = builtins.listToAttrs (
            map (lang: {
              name = lang;
              value = [
                {
                  type = "pwa-node";
                  request = "launch";
                  name = "Launch file";
                  program = "\${file}";
                  cwd = "\${workspaceFolder}";
                }
                {
                  type = "pwa-node";
                  request = "attach";
                  name = "Attach";
                  processId.__raw = ''require ("dap.utils").pick_process'';
                  cwd = "\${workspaceFolder}";
                }
                {
                  type = "pwa-node";
                  request = "attach";
                  name = "Auto Attach";
                  cwd.__raw = "vim.fn.getcwd()";
                  restart = true;
                }

                {
                  type = "pwa-node";
                  request = "launch";
                  name = "Debug Server (Production Build)";
                  skipFiles = [
                    "<node_internals>/**"
                  ];
                  program.__raw = "vim.fn.getcwd() .. '/build/server/index.js'";
                  outFiles = [
                    "\${workspaceFolder}/build/**/*.js"
                  ];
                  console = "integratedTerminal";
                }
                {
                  type = "pwa-node";
                  request = "launch";
                  name = "Debug with Node Inspect";
                  skipFiles = [
                    "<node_internals>/**"
                  ];
                  runtimeExecutable = lib.getExe pkgs.nodejs;
                  runtimeArgs = [
                    "--inspect"
                    "./build/server/index.js"
                  ];
                  console = "integratedTerminal";
                  cwd = "\${workspaceFolder}";
                }
                {
                  type = "pwa-node";
                  request = "launch";
                  name = "Debug with Node Inspect (Break)";
                  skipFiles = [
                    "<node_internals>/**"
                  ];
                  runtimeExecutable = lib.getExe pkgs.nodejs;
                  runtimeArgs = [
                    "--inspect-brk"
                    "./build/server/index.js"
                  ];
                  console = "integratedTerminal";
                  cwd = "\${workspaceFolder}";
                }
                {
                  type = "pwa-node";
                  request = "launch";
                  name = "Debug Vite Dev Server";
                  skipFiles = [
                    "<node_internals>/**"
                  ];
                  runtimeExecutable = lib.getExe pkgs.nodejs;
                  runtimeArgs = [
                    "--inspect"
                    "node_modules/vite/bin/vite.js"
                    "--host"
                  ];
                  console = "integratedTerminal";
                  cwd = "\${workspaceFolder}";
                }
                {
                  type = "pwa-node";
                  request = "launch";
                  name = "Debug Vitest Current File";
                  runtimeExecutable = lib.getExe pkgs.nodejs;
                  program.__raw = ''
                    function()
                      local _, path = _dap_find_pkg(vim.fn.expand("%:p:h"), "node_modules/vitest/vitest.mjs")
                      return path or (vim.fn.getcwd() .. "/node_modules/vitest/vitest.mjs")
                    end
                  '';
                  args = [
                    "run"
                    "\${file}"
                    "--no-file-parallelism"
                  ];
                  cwd.__raw = ''
                    function()
                      local root = _dap_find_pkg(vim.fn.expand("%:p:h"), "node_modules/vitest/vitest.mjs")
                      return root or vim.fn.getcwd()
                    end
                  '';
                  console = "integratedTerminal";
                  skipFiles = [
                    "<node_internals>/**"
                    "**/node_modules/**"
                  ];
                }
              ];
            }) jsFiletypes
          );
        };
      };

      lsp.servers = {
        biome = {
          enable = true;
          packageFallback = true;
          config.workspace_required = true;
        };
        eslint = {
          enable = true;
          packageFallback = true;
          config = {
            # Keep formatting with conform/prettier/biome and let ESLint focus on
            # diagnostics and fix/code-action workflows.
            settings.format = false;
            workspace_required = true;
          };
        };
        oxlint = {
          enable = true;
          packageFallback = true;
          config = {
            workspace_required = true;
            settings = {
              run = "onSave";
              typeAware = false;
            };
            before_init.__raw = ''
              function(init_params, config)
                local base_path = vim.api.nvim_get_runtime_file("lsp/oxlint.lua", false)[1]
                if base_path then
                  local oxlint_base = assert(loadfile(base_path))()
                  if oxlint_base.before_init then
                    oxlint_base.before_init(init_params, config)
                  end
                end
                -- Prevents oxlint from re-checking on every keystroke
                if init_params.capabilities.workspace then
                  init_params.capabilities.workspace.diagnostics = nil
                end
              end
            '';
          };
        };
        tailwindcss = {
          enable = true;
          packageFallback = true;
          config.workspace_required = true;
        };
        tsgo = {
          enable = true;
          packageFallback = true;
          # TODO: remove this later once typescript-go is removed in nixvim
          package = pkgs.typescript;
          config.cmd = [
            "tsc"
            "--lsp"
            "--stdio"
          ];
        };
      };
    };
}
