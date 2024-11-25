local M = {}
--------------------------------------------------------------------------------

---@class Chainsaw.config
local defaultConfig = {
	-- The marker should be a unique string, since lines with it are highlighted
	-- and since `removeLogs` will remove any line with it. Thus, emojis or
	-- unique strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- Highlight lines with the marker.
	-- When using `lazy.nvim`, you need to add `event = VeryLazy` to the plugin
	-- spec to have existing log statements highlighted as well.
	---@type string|false
	logHighlightGroup = "Visual",

	-- emojis used for `emojiLog`
	logEmojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },

	logStatements = require("chainsaw.log-statements-data"),
}
M.config = defaultConfig

--------------------------------------------------------------------------------

---@param userConfig? Chainsaw.config
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
	M.config.logStatements = require("chainsaw.superset-inheritance").insert(M.config.logStatements)

	if not M.config.marker or M.config.marker == "" then
		local msg = "`marker` must not be empty."
		require("chainsaw.utils").notify(msg, "warn")
		return
	end
	require("chainsaw.highlight").highlightExistingLogs()
end

--------------------------------------------------------------------------------
return M
