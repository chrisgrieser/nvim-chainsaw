local M = {}
--------------------------------------------------------------------------------

---@class Chainsaw.config
local defaultConfig = {
	-- The marker should be a unique string, since lines with it are highlighted
	-- and since `removeLogs` will remove any line with it. Thus, emojis or
	-- strings like "[Chainsaw]" are recommended.
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

---@param data logStatementData
---@return logStatementData
local function supersetLogInheritance(data)
	local logTypes = vim.tbl_keys(data)

	-- JS supersets inherit from `typescript`, and in turn `typescript` form
	-- `javascript`, if it set itself.
	local jsSupersets = { "typescriptreact", "javascriptreact", "vue", "svelte" }
	for _, logType in ipairs(logTypes) do
		if not data[logType].typescript then data[logType].typescript = data[logType].javascript end
		for _, lang in ipairs(jsSupersets) do
			data[logType][lang] = data[logType].typescript
		end
	end

	-- shell supersets inherit from `sh`, if they have no config of their own.
	local shellSupersets = { "bash", "zsh", "fish", "nu" }
	for _, logType in ipairs(logTypes) do
		for _, lang in ipairs(shellSupersets) do
			if not data[logType][lang] then data[logType][lang] = data[logType].sh end
		end
	end

	-- CSS supersets inherit from `css`, if they have no config of their own.
	local cssSupersets = { "scss", "less", "sass" }
	for _, logType in ipairs(logTypes) do
		for _, lang in ipairs(cssSupersets) do
			if not data[logType][lang] then data[logType][lang] = data[logType].css end
		end
	end

	-- `nvim-lua` inherits from `lua`, if it has no config of its own.
	for _, logType in ipairs(logTypes) do
		if not data[logType].nvim_lua then data[logType].nvim_lua = data[logType].lua end
	end
	return data
end

--------------------------------------------------------------------------------

---@param userConfig? Chainsaw.config
function M.setup(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
	M.config.logStatements = supersetLogInheritance(M.config.logStatements)

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
