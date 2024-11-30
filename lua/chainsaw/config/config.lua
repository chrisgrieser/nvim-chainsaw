local M = {}
--------------------------------------------------------------------------------

---@class Chainsaw.config
local defaultConfig = {
	-- The marker should be a unique string, since signs and highlgiths are based
	-- on it and since `.removeLogs()` will remove any line with it. Thus, emojis
	-- or unique strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- Appearance of lines with the marker
	visuals = {
		sign = "󰹈",
		signHlgroup = "DiagnosticSignInfo",
		statuslineIcon = "󰹈",
		lineHlgroup = false,

		nvimSatelliteIntegration = {
			enabled = true,
			hlgroup = "DiagnosticSignInfo",
			icon = "▪",
			leftOfScrollbar = false,
			priority = 40, -- compared to other handlers (diagnostics are 50)
		},
	},

	-- configuration for specific logtypes
	logtypes = {
		variableLog = {
			-- experimental:
			-- uses concise debug statement specifically for nvim-lua via the
			-- global function `Chainsaw`. (To prevent the spurious diagnostic from
			-- lua_ls, set `settings.Lua.diagnostics.globals = { "Chainsaw" }` in
			-- its settings.)
			specialNvimLuaDebug = false,
		},
		emojiLog = {
			emojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },
		},
	},

	-- If a filetype has no configuration for a specific logtype, then it will
	-- look for the configuration for a superset of that filetype.
	supersets = {
		nvim_lua = "lua", -- `nvim_lua` config is used when in nvim-lua
		typescript = "javascript",
		typescriptreact = "typescript",
		javascriptreact = "javascript",
		vue = "typescript",
		svelte = "typescript",
		bash = "sh",
		zsh = "sh",
		fish = "sh",
		scss = "css",
		less = "css",
		sass = "css",
	},

	logStatements = require("chainsaw.config.log-statements-data"),
}
M.config = defaultConfig

--------------------------------------------------------------------------------

---superset-inheritance via setting `__index` metatable
---@param tableToEnhance table
function M.supersetInheritance(tableToEnhance)
	setmetatable(tableToEnhance, {
		__index = function(_table, key)
			local targetFt = M.config.supersets[key]
			if not targetFt then return nil end
			return _table[targetFt]
		end,
	})
end

--------------------------------------------------------------------------------

---@param userConfig? Chainsaw.config
function M.setup(userConfig)
	local warn = require("chainsaw.utils").warn

	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})

	for _, logType in pairs(M.config.logStatements) do
		M.supersetInheritance(logType)
	end

	if M.config.logtypes.variableLog.specialNvimLuaDebug then
		require("chainsaw.nvim-debug") -- actives `Chainsaw` global var
		M.config.logStatements.variableLog.nvim_lua = "Chainsaw({{var}}) -- {{marker}}"
	end

	-- DEPRECATION
	if M.config.logEmojis then ---@diagnostic disable-line: undefined-field
		local msg = "Config `logEmojis` is deprecated. Use `logtypes.emojiLog.emojis` instead."
		warn(msg)
	end

	-- DEPRECATION
	if M.config.logHighlightGroup then ---@diagnostic disable-line: undefined-field
		local msg = "Config `logHighlightGroup` is deprecated. Use `loglines.lineHlgroup` instead."
		warn(msg)
	end

	-- DEPRECATION
	if M.config.loglines then ---@diagnostic disable-line: undefined-field
		warn("Config `loglines` is deprecated. Use `visuals` instead.")
	end

	-- VALIDATE
	local emojis = M.config.logtypes.emojiLog.emojis
	if not emojis or type(emojis) ~= "table" or #emojis == 0 then
		M.config.logtypes.emojiLog.emojis = nil
		warn("Config `logtypes.emojiLog.emojis` is not a list of strings.")
	end
	if not M.config.marker or M.config.marker == "" then
		warn("Config `marker` must not be empty.")
	end

	-- initialize
	require("chainsaw.visuals.styling").styleExistingLogs()
	require("chainsaw.visuals.satellite-integration")
end

--------------------------------------------------------------------------------
return M
