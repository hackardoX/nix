-- Provider-based dynamic formatter routing for conform.nvim.
--
-- formatters_by_ft values are functions resolved per-buffer at format
-- time: this core inspects the buffer's project (upward config-file
-- search) through a declarative per-ecosystem spec and returns the
-- formatter chain owned by the detected toolchain.
--
-- Ecosystem specs live in providers/<name>.lua next to this file and
-- contain DATA ONLY (no logic); adding an ecosystem means dropping a new
-- spec file there, wiring its filetypes in nix and adding its formatter
-- packages (conform-nvim's autoInstall only scans static formatters_by_ft
-- lists, it cannot see names produced dynamically).
--
-- Detection results are cached for the session (per directory); creating
-- a new config file takes effect after a restart or
-- :lua require("dev.format_routing").clear_cache().

local M = {}

local provider_cache = {}
local found_cache = {}
local manifest_cache = {}

------------------------------------------------------------------------
-- provider spec schema
------------------------------------------------------------------------
-- A provider file returns a table with the following keys:
--
--   tools = {                                   [required]
--     <tool> = {
--       files = { "config.a", "config.b", ... },  -- upward file search
--       manifest = { file = "package.json",       -- optional: walk up dirs
--                    field = "someField" },       -- looking for a manifest
--                                                  -- containing `field`
--       sections = { file = "pyproject.toml",     -- optional: walk up dirs
--                    list = { "tool.ruff", ... }},-- looking for a TOML file
--                                                  -- with a [section] header
--     },                                          --
--   },
--     Every tool listed here is probed per buffer directory ("detected"
--     if any check hits). Tool names are local to the spec and only
--     referenced by the sections below.
--
--   owners = { "tool_a", "tool_b", ... },       [required]
--     Formatting authorities in precedence order. The first detected
--     tool (not excluded via owner_skip for the buffer filetype) "owns"
--     the buffer; exactly zero or one owner ends up in the chain.
--
--   owner_formatter = { <tool> = "<conform name>" },  [required]
--     Maps an owner tool to the conform formatter name emitted.
--
--   owner_skip = { <tool> = { <filetype> = true } }   [optional]
--     Owners that cannot handle certain filetypes (e.g. biome cannot
--     format scss/less): they are passed over for those buffers, falling
--     through to the next owner or the fallback.
--
--   helpers = {                                 [optional]
--     { tool = "<tool>", formatter = "<conform name>",
--       before = true|false,
--       filetypes = { <filetype> = true, ... } },
--   },
--     Secondary tools running around the owner. A helper fires only when
--     BOTH its tool is detected AND the buffer filetype is listed.
--     before = true  -> runs BEFORE the owner (e.g. a lint autofixer
--                       cleaning up issues before biome/prettier formats).
--     before = false -> runs AFTER the owner (least-preferred finishing
--                       step, e.g. eslint_d applying lint fixes after the
--                       owner formatted; in a tool-only project it then
--                       effectively owns the formatting).
--     Detected helpers also suppress the fallback (see below): if a
--     project configures a tool relevant to this filetype, respect it
--     instead of guessing with the fallback.
--
--   fallback = {                                [optional]
--     default = "<conform name>",
--     by_filetype = { <filetype> = "<conform name>" },
--   },
--     Bare-project default, emitted ONLY when no owner was detected and
--     no filetype-relevant helper fired. by_filetype overrides cover
--     filetypes the default cannot handle.
--
-- Chain assembly:
--   [helpers before=true] -> [owner formatter | fallback] -> [helpers before=false]

---@param name string
---@return table the provider spec
local function provider(name)
	local cached = provider_cache[name]
	if cached then
		return cached
	end
	local spec = require("dev.format_routing.providers." .. name)
	assert(spec.tools, "format provider '" .. name .. "' has no tools")
	assert(spec.owners, "format provider '" .. name .. "' has no owners")
	provider_cache[name] = spec
	return spec
end

------------------------------------------------------------------------
-- shared detection helpers (cached)
------------------------------------------------------------------------

local function buf_path(bufnr)
	bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" or vim.bo[bufnr].buftype ~= "" then
		return nil
	end
	return name
end

local function find_upward(dir, names)
	local key = dir .. ":" .. table.concat(names, ",")
	local cached = found_cache[key]
	if cached ~= nil then
		return cached or nil
	end
	local found = vim.fs.find(names, { path = dir, upward = true, limit = 1, type = "file" })[1]
	found_cache[key] = found or false
	return found
end

-- Per-extension manifest readers; unknown extensions are treated as a
-- miss (e.g. toml: not parsed yet). Adding a format = adding an entry.
local readers = {
	json = function(text)
		local ok, decoded = pcall(vim.json.decode, text)
		return ok and type(decoded) == "table" and decoded or nil
	end,
}

local function read_manifest(path)
	local cached = manifest_cache[path]
	if cached ~= nil then
		return cached or nil
	end
	local reader = readers[vim.fn.fnamemodify(path, ":e"):lower()]
	local decoded
	if reader then
		local f = io.open(path, "r")
		if f then
			local ok, result = pcall(reader, f:read("*a"))
			f:close()
			decoded = ok and result or nil
		end
	end
	manifest_cache[path] = decoded or false
	return manifest_cache[path] or nil
end

---Walk up from `dir` looking for a manifest file containing `field`
---(parsed by file extension via `readers`).
local function manifest_field(dir, file, field)
	-- note: vim.fs.parents excludes the starting dir, hence the explicit first entry
	local dirs = { dir }
	for parent in vim.fs.parents(dir) do
		table.insert(dirs, parent)
	end
	for _, parent in ipairs(dirs) do
		local path = vim.fs.joinpath(parent, file)
		if vim.uv.fs_stat(path) then
			local decoded = read_manifest(path)
			if decoded and decoded[field] ~= nil then
				return path
			end
		end
	end
	return nil
end

---Walk up from `dir` looking for a TOML file containing any of the
---`[sections]` headers (line scan only; no full TOML parsing -- headers
---inside string literals are not possible at line start after stripping
---comments/indentation, which is good enough for tool detection).
local section_cache = {}
local function toml_sections(dir, file, sections)
	local key = dir .. ":" .. file .. ":" .. table.concat(sections, ",")
	local cached = section_cache[key]
	if cached ~= nil then
		return cached or nil
	end

	local patterns = {}
	for _, sec in ipairs(sections) do
		-- match [sec] and [[sec]] with optional indentation/trailing comment
		table.insert(patterns, "^%s*%[" .. vim.pesc(sec) .. "%]%s*$")
		table.insert(patterns, "^%s*%[%[" .. vim.pesc(sec) .. "%]%]%s*$")
	end

	local hit
	-- note: vim.fs.parents excludes the starting dir, hence the explicit first entry
	local dirs = { dir }
	for parent in vim.fs.parents(dir) do
		table.insert(dirs, parent)
	end
	for _, parent in ipairs(dirs) do
		local path = vim.fs.joinpath(parent, file)
		local f = vim.uv.fs_stat(path) and io.open(path, "r")
		if f then
			for line in f:lines() do
				line = line:gsub("#.*$", "")
				for _, pat in ipairs(patterns) do
					if line:match(pat) then
						hit = path
						break
					end
				end
				if hit then
					break
				end
			end
			f:close()
		end
		if hit then
			break
		end
	end
	section_cache[key] = hit or false
	return hit
end

local function detect(tools, dir)
	local detected = {}
	for tool, rule in pairs(tools) do
		detected[tool] = (rule.files and find_upward(dir, rule.files) or nil)
			or (rule.manifest and manifest_field(dir, rule.manifest.file, rule.manifest.field) or nil)
			or (rule.sections and toml_sections(dir, rule.sections.file, rule.sections.list) or nil)
	end
	return detected
end

local function owner_of(spec, detected, filetype)
	for _, owner in ipairs(spec.owners) do
		local skipped = spec.owner_skip and spec.owner_skip[owner] and spec.owner_skip[owner][filetype]
		if detected[owner] and not skipped then
			return owner
		end
	end
	return nil
end

local function matching_helpers(spec, detected, filetype)
	local before, after = {}, {}
	for _, helper in ipairs(spec.helpers or {}) do
		if detected[helper.tool] and helper.filetypes[filetype] then
			table.insert(helper.before and before or after, helper.formatter)
		end
	end
	return before, after
end

------------------------------------------------------------------------
-- conform formatters_by_ft adapter
------------------------------------------------------------------------

---Build a conform.nvim formatters_by_ft value resolving per buffer.
---@param provider_name string
---@param filetype string
---@return fun(bufnr: integer): string[]
function M.resolver(provider_name, filetype)
	return function(bufnr)
		local path = buf_path(bufnr)
		if not path then
			return {}
		end

		local spec = provider(provider_name)
		local detected = detect(spec.tools, vim.fs.dirname(path))
		local owner = owner_of(spec, detected, filetype)
		local before, after = matching_helpers(spec, detected, filetype)

		local chain = vim.list_extend({}, before)
		if owner then
			table.insert(chain, spec.owner_formatter[owner])
		elseif #before == 0 and #after == 0 and spec.fallback then
			-- bare project: no owner and no toolchain relevant to this filetype
			table.insert(
				chain,
				spec.fallback.by_filetype and spec.fallback.by_filetype[filetype] or spec.fallback.default
			)
		end
		return vim.list_extend(chain, after)
	end
end

function M.clear_cache()
	found_cache = {}
	manifest_cache = {}
	section_cache = {}
end

return M
