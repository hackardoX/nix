{ lib, ... }:
{
  flake.modules.homeManager.dev = {
    programs.java.enable = true;
  };

  flake.modules.nixvim.dev =
    { pkgs, ... }:
    {
      extraPackages = [
        pkgs.jdk
        pkgs.jdt-language-server
        pkgs.maven
        pkgs.gradle
        pkgs.unzip
        pkgs.lombok
      ];
      extraConfigLuaPre = ''
        _G._jdtls = _G._jdtls or {}

        function _G._jdtls.find_root(startpath)
          local current = startpath and vim.fs.dirname(startpath) or nil
          local gradle_settings_root = nil
          local nearest_maven_root = nil
          local nearest_gradle_root = nil

          while current and current ~= "" and current ~= "." do
            local has_gradle_settings =
              vim.uv.fs_stat(current .. "/settings.gradle")
              or vim.uv.fs_stat(current .. "/settings.gradle.kts")
            local has_maven_root =
              vim.uv.fs_stat(current .. "/pom.xml")
              or vim.uv.fs_stat(current .. "/mvnw")
            local has_gradle_root =
              vim.uv.fs_stat(current .. "/build.gradle")
              or vim.uv.fs_stat(current .. "/build.gradle.kts")
              or vim.uv.fs_stat(current .. "/gradlew")

            if has_gradle_settings then
              gradle_settings_root = current
            end

            if not nearest_maven_root and has_maven_root then
              nearest_maven_root = current
            end

            if not nearest_gradle_root and has_gradle_root then
              nearest_gradle_root = current
            end

            if vim.uv.fs_stat(current .. "/.git") then
              break
            end

            local parent = vim.fs.dirname(current)
            if not parent or parent == current then
              break
            end

            current = parent
          end

          return gradle_settings_root or nearest_maven_root or nearest_gradle_root
        end

        function _G._jdtls.find_root_for_buffer(bufnr)
          local path = vim.api.nvim_buf_get_name(bufnr)
          if path == "" then
            return nil
          end

          return _G._jdtls.find_root(path)
        end

        function _G._jdtls.workspace_dir(root, kind)
          return vim.fn.stdpath("cache")
            .. "/jdtls/"
            .. vim.fn.sha256(root)
            .. "/"
            .. kind
        end

        vim.api.nvim_create_autocmd("FileType", {
          pattern = "java",
          callback = function(args)
            local bufnr = args.buf
            local root = _G._jdtls.find_root_for_buffer(bufnr)
            if not root then return end

            local bundles = vim
              .iter({
                vim.fn.glob(
                  "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug/server/*.jar",
                  true, true
                ),
                vim.fn.glob(
                  "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test/server/*.jar",
                  true, true
                ),
              })
              :flatten()
              :totable()

            if _G._spring_boot_jdtls_bundles then
              vim.list_extend(bundles, _G._spring_boot_jdtls_bundles())
            end

            vim.lsp.start({
              name = "jdtls",
              cmd = {
                "${lib.getExe pkgs.jdt-language-server}",
                "-data",          _G._jdtls.workspace_dir(root, "data"),
                "-configuration", _G._jdtls.workspace_dir(root, "config"),
                "--jvm-arg=-javaagent:${pkgs.lombok}/share/java/lombok.jar",
                "--jvm-arg=-Xmx4G",
                "--jvm-arg=-XX:+UseG1GC",       
              },
              root_dir = root,
              init_options = { bundles = bundles },
            }, { bufnr = bufnr })
          end
        })
      '';

      plugins.java =
        let
          nvim-java-core-fixed = pkgs.vimPlugins.nvim-java-core.overrideAttrs (old: {
            postPatch = ''
              ${old.postPatch or ""}

              substituteInPlace lua/java-core/ls/clients/jdtls-client.lua \
                --replace-fail "self.client.request(method, params, on_response, buffer)" "self.client:request(method, params, on_response, buffer)"
            '';
          });

          nvim-java-refactor-fixed = pkgs.vimPlugins.nvim-java-refactor.overrideAttrs (old: {
            postPatch = ''
              ${old.postPatch or ""}

              substituteInPlace lua/java-refactor/init.lua \
                --replace-fail "local event = require('java-core.utils.event')" "local event = require('java-core.utils.event')

              local function register_api(module, path, command, opts)
                local name = 'Java'

                for _, word in ipairs(path) do
                  for _, sub_word in ipairs(vim.split(word, '_')) do
                    name = name .. sub_word:sub(1, 1):upper() .. sub_word:sub(2)
                  end
                end

                vim.api.nvim_create_user_command(name, command, opts or {})

                local func_name = table.remove(path)
                local node = module

                for _, key in ipairs(path) do
                  node[key] = node[key] or {}
                  node = node[key]
                end

                node[func_name] = command
              end" \
                --replace-fail "require('java').register_api({ 'refactor', api_name }, api, { range = 2 })" "local java = require('java')
                  register_api(java, { 'refactor', api_name }, api, { range = 2 })" \
                --replace-fail "require('java').register_api({ 'build', api_name }, api, {})" "local java = require('java')
                  register_api(java, { 'build', api_name }, api, {})"

              printf '\nM.setup = M.setup or function() end\nreturn M\n' >> lua/java-refactor/init.lua
            '';
          });
        in
        {
          enable = true;
          lazyLoad.settings.ft = [ "java" ];
          package = pkgs.vimPlugins.nvim-java.overrideAttrs (old: {
            # TODO: Remove when nvim-java/nvim-java#487 is merged and reaches nixpkgs.
            patches = (old.patches or [ ]) ++ [
              (pkgs.fetchpatch {
                name = "nvim-java-pr-487.patch";
                url = "https://patch-diff.githubusercontent.com/raw/nvim-java/nvim-java/pull/487.patch";
                hash = "sha256-qe89H0pNd0qOuvilrhWfZqHrqy3PV/E/wguEUad0nEA=";
              })
            ];
            dependencies = map (
              dep:
              if dep.pname == "nvim-java-core" then
                nvim-java-core-fixed
              else if dep.pname == "nvim-java-refactor" then
                nvim-java-refactor-fixed
              else
                dep
            ) old.dependencies;

            postPatch = ''
              ${old.postPatch or ""}

              substituteInPlace lua/java.lua \
                --replace-fail "table.insert(to_install, { name = 'jdtls', version = config.jdtls.version })" "if config.jdtls.enable ~= false then
                table.insert(to_install, { name = 'jdtls', version = config.jdtls.version })
              end" \
                --replace-fail "pkgm:install_all(" "if config.pkgm and config.pkgm.enable == false then
                to_install = {}
              end

              pkgm:install_all(" \
                --replace-fail "vim.lsp.enable('jdtls')" "" \
                --replace-fail "require('java.startup.lsp_setup').setup(config)" "if config.jdtls.enable ~= false then
                require('java.startup.lsp_setup').setup(config)
                vim.lsp.enable('jdtls')
              end"
            '';
          });

          settings = {
            # Keep JDK management in Nix
            jdk.auto_install = false;
            # Keep nvim-java's feature APIs, but use the Nix-managed JDTLS below.
            jdtls.enable = false;
            pkgm.enable = false;
            # Spring Boot is configured by the root spring-boot plugin module.
            spring_boot_tools = {
              enable = false;
            };
            root_markers = [
              "pom.xml"
              "mvnw"
              "settings.gradle"
              "settings.gradle.kts"
              "build.gradle"
              "build.gradle.kts"
              "gradlew"
            ];
          };
        };
    };
}
