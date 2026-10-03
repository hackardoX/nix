-- Python ecosystem spec: formatter routing for python buffers.
-- See ../init.lua for the schema documentation.

return {
	tools = {
		ruff = {
			files = { "ruff.toml", ".ruff.toml" },
			sections = {
				file = "pyproject.toml",
				list = { "tool.ruff", "tool.ruff-format", "tool.ruff.lint" },
			},
		},
		black = {
			sections = { file = "pyproject.toml", list = { "tool.black" } },
		},
	},

	owners = { "ruff", "black" },
	owner_formatter = { ruff = "ruff_format", black = "black" },

	fallback = { default = "ruff_format" },
}
