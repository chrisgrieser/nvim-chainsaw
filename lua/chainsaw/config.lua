local M = {}
--------------------------------------------------------------------------------

---@class pluginConfig
local defaultConfig = {
	-- The marker should be a unique string, since `removeLogs` will remove
	-- any line with it. Emojis or strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- emojis used for `beepLog`
	beepEmojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },

	logStatements = require("chainsaw.log-statements-data"),
}

M.config = defaultConfig -- in case user does not call `setup`

---@param userConfig? pluginConfig
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
end

--------------------------------------------------------------------------------
return M
