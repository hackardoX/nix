let
  formatterLanguages = [
    "typescript"
    "javascript"
    "javascriptreact"
    "typescriptreact"
  ];
in
{ lib, ... }:
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ nodejs ];
    };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = with pkgs; [
        biome
        eslint_d
      ];
      plugins = {
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = builtins.listToAttrs (
              map (lang: {
                name = lang;
                value = [
                  "biome"
                  "eslint_d"
                ];
              }) formatterLanguages
            );
            formatters = {
              biome = {
                command = lib.getExe pkgs.biome;
              };
              eslint_d = {
                command = lib.getExe pkgs.eslint_d;
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
            }) formatterLanguages
          );
        };
        lsp.servers = {
          biome.enable = true;
          eslint.enable = true;
          tsgo.enable = true;
        };
      };
    };
}
