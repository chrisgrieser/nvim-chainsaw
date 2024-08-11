local M = {}
--------------------------------------------------------------------------------

---@class pluginConfig
local defaultConfig = {
	-- The marker should be a unique string, since lines with it are highlighted
	-- and since `removeLogs` will remove any line with it. Thus, emojis or
	-- strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- Highlight lines with the marker.
	-- lazy.nvim users:, you need to add `event = VeryLazy` to the plugin spec to
	-- have existing log statements highlighted as well.
	---@type string|false false to disable
	logHighlightGroup = "Visual",

	-- emojis used for `beepLog`
	beepEmojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },

	logStatements = require("chainsaw.log-statements-data"),
}

M.config = defaultConfig -- in case user does not call `setup`

---@param userConfig? pluginConfig
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})

	if M.config.logHighlightGroup then
		if M.config.marker == "" then
			local msg = "You cannot use `highlight` with an empty `marker`."
			require("chainsaw.utils").notify(msg, "warn")
			return
		end
		require("chainsaw.highlight").highlightExistingLogs()
	end
end

--------------------------------------------------------------------------------
return M
