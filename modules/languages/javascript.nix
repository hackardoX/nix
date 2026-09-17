{ lib, ... }:
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
              (lib.getExe' pkgs.typescript "tsserver")
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
      extraPackages = with pkgs; [
        biome
        eslint_d
        oxfmt
        typescript
      ];
      plugins = {
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = builtins.listToAttrs (
              map (lang: {
                name = lang;
                value = [
                  "oxfmt"
                  "biome"
                  "eslint_d"
                ];
              }) jsFiletypes
            );
            formatters = {
              oxfmt = {
                command = lib.getExe pkgs.oxfmt;
                stdin = true;
                args = [
                  "--stdin-filepath"
                  "$FILENAME"
                ];
                require_cwd = true;
                cwd.__raw = ''
                  require("conform.util").root_file({
                    ".oxfmtrc.json", ".oxfmtrc.jsonc", ".oxfmtrc",
                    "oxfmt.config.ts", "oxfmt.config.mts", "oxfmt.config.js", "oxfmt.config.mjs",
                  })
                '';
              };
              biome = {
                command = lib.getExe pkgs.biome;
                require_cwd = true;
              };
              eslint_d = {
                command = lib.getExe pkgs.eslint_d;
                require_cwd = true;
                cwd.__raw = ''
                  require("conform.util").root_file({
                    ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yaml", ".eslintrc.yml", ".eslintrc.json",
                    "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs",
                    "eslint.config.ts", "eslint.config.mts", "eslint.config.cts",
                  })
                '';
              };
            };
          };
        };
        dap = {
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
                  protocol = "inspector";
                  sourceMaps = true;
                  resolveSourceMapLocations = [
                    "\${workspaceFolder}/**"
                    "!**/node_modules/**"
                  ];
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
                  sourceMaps = true;
                  resolveSourceMapLocations = [
                    "\${workspaceFolder}/**"
                    "!**/node_modules/**"
                  ];
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
                  sourceMaps = true;
                  resolveSourceMapLocations = [
                    "\${workspaceFolder}/**"
                    "!**/node_modules/**"
                  ];
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
                  sourceMaps = true;
                  resolveSourceMapLocations = [
                    "\${workspaceFolder}/**"
                    "!**/node_modules/**"
                  ];
                }
                {
                  type = "pwa-node";
                  request = "attach";
                  name = "Attach to Process";
                  port = 9229;
                  restart = true;
                  skipFiles = [
                    "<node_internals>/**"
                  ];
                  sourceMaps = true;
                  resolveSourceMapLocations = [
                    "\${workspaceFolder}/**"
                    "!**/node_modules/**"
                  ];
                  cwd = "\${workspaceFolder}";
                }
              ];
            }) jsFiletypes
          );
        };
      };

      lsp.servers = {
        biome = {
          enable = true;
          config.workspace_required = true;
        };
        eslint = {
          enable = true;
          config = {
            # Keep formatting with conform/prettier/biome and let ESLint focus on
            # diagnostics and fix/code-action workflows.
            settings.format = false;
            workspace_required = true;
          };
        };
        oxlint = {
          enable = true;
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
        stylelint_lsp = {
          enable = true;
          config = {
            cmd = [
              (lib.getExe pkgs.stylelint-lsp)
              "--stdio"
            ];
            workspace_required = true;
          };
        };
        tailwindcss = {
          enable = true;
          config.workspace_required = true;
        };
        tsgo = {
          enable = true;
          package = pkgs.typescript; # TODO: remove this later once typescript-go is removed in nixvim
        };
      };
    };
}
