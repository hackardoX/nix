-- Web ecosystem spec: detection maps and formatter routing for
-- javascript/typescript/json/css family buffers.
-- See ../init.lua for the schema documentation.

local js_like = { javascript = true, javascriptreact = true, typescript = true, typescriptreact = true }

return {
	tools = {
		biome = { files = { "biome.json", "biome.jsonc" } },
		oxfmt = {
			files = {
				".oxfmtrc.json",
				".oxfmtrc.jsonc",
				".oxfmtrc",
				"oxfmt.config.ts",
				"oxfmt.config.mts",
				"oxfmt.config.js",
				"oxfmt.config.mjs",
			},
		},
		prettier = {
			files = {
				".prettierrc",
				".prettierrc.json",
				".prettierrc.yml",
				".prettierrc.yaml",
				".prettierrc.json5",
				".prettierrc.js",
				".prettierrc.cjs",
				".prettierrc.mjs",
				".prettierrc.toml",
				"prettier.config.js",
				"prettier.config.cjs",
				"prettier.config.mjs",
				"prettier.config.ts",
				"prettier.config.mts",
				"prettier.config.cts",
			},
			manifest = { file = "package.json", field = "prettier" },
		},
		eslint = {
			files = {
				".eslintrc",
				".eslintrc.js",
				".eslintrc.cjs",
				".eslintrc.yaml",
				".eslintrc.yml",
				".eslintrc.json",
				"eslint.config.js",
				"eslint.config.mjs",
				"eslint.config.cjs",
				"eslint.config.ts",
				"eslint.config.mts",
				"eslint.config.cts",
			},
			manifest = { file = "package.json", field = "eslintConfig" },
		},
	},

	owners = { "biome", "oxfmt", "prettier" },
	owner_formatter = { biome = "biome", oxfmt = "oxfmt", prettier = "prettierd" },
	-- biome cannot format scss/less (formatter disabled upstream)
	owner_skip = { biome = { scss = true, less = true } },

	helpers = {
		-- eslint_d is the least preferred step: it fixes lint issues after the
		-- owner formatted, and owns formatting only in eslint-only projects
		{ tool = "eslint", formatter = "eslint_d", before = false, filetypes = js_like },
	},

	fallback = { default = "biome", by_filetype = { scss = "oxfmt", less = "oxfmt" } },
}
