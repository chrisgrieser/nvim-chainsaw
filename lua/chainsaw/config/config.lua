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

	logtypes = {
		emojiLog = {
			emojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },
		},
	},

	logStatements = require("chainsaw.config.log-statements-data"),
}
M.config = defaultConfig

--------------------------------------------------------------------------------

local supersets = {
	nvim_lua = "lua",
	typescript = "javascript",
	typescriptreact = "typescript",
	javascriptreact = "javascript",
	vue = "typescript",
	svelte = "typescript",
	bash = "sh",
	zsh = "sh",
	fish = "sh",
	nu = "sh",
	scss = "css",
	less = "css",
	sass = "css",
}

---@param userConfig? Chainsaw.config
function M.setup(userConfig)
	local warn = require("chainsaw.utils").warn

	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})

	-- superset-inheritance via setting `__index` metatable for each logtype
	for _, logType in pairs(M.config.logStatements) do
		setmetatable(logType, {
			__index = function(type, key)
				local targetFt = supersets[key]
				if not targetFt then return nil end
				return type[targetFt]
			end,
		})
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
