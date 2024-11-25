local M = {}
--------------------------------------------------------------------------------

---@class Chainsaw.config
local defaultConfig = {
	-- The marker should be a unique string, since lines with it are highlighted
	-- and since `.removeLogs()` will remove any line with it. Thus, emojis or
	-- unique strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	loglines = {
		-- Appearance of lines with the marker. Leave empty to disable any of them.
		-- (When using `lazy.nvim`, you need to add `event = VeryLazy` to the plugin
		-- spec to have existing log statements styled as well.)
		lineHlgroup = "Visual",
		sign = "🪚", -- can also use nerdfont icon since it's solely used in nvim: 󰹈
		signHlgroup = "CursorLineNr",
	},

	logtypes = {
		emojiLog = {
			emojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },
		},
	},

	logStatements = require("chainsaw.log-statements-data"),
}
M.config = defaultConfig

--------------------------------------------------------------------------------

---@param userConfig? Chainsaw.config
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
	M.config.logStatements = require("chainsaw.superset-inheritance").insert(M.config.logStatements)

	-- DEPRECATION
	if M.config.logEmojis then ---@diagnostic disable-line: undefined-field
		local msg = "Config `logEmojis` is deprecated. Use `logtypes.emojiLog.emojis` instead."
		require("chainsaw.utils").warn(msg)
	end

	-- DEPRECATION
	if M.config.logHighlightGroup then ---@diagnostic disable-line: undefined-field
		local msg = "Config `logHighlightGroup` is deprecated. Use `loglines.lineHlgroup` instead."
		require("chainsaw.utils").warn(msg)
	end

	if not M.config.marker or M.config.marker == "" then
		require("chainsaw.utils").warn("Config `marker` must not be empty.")
		return
	end
	require("chainsaw.styling").styleExistingLogs()
end

--------------------------------------------------------------------------------
return M
