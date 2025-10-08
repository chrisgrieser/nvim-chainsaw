local M = {}
--------------------------------------------------------------------------------

---@class Chainsaw.config
local defaultConfig = {
	-- The marker should be a unique string, since signs and highlights are based
	-- on it. Furthermore, `.removeLogs()` will remove any line with it. Thus,
	-- unique emojis or strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- Appearance of lines with the marker
	visuals = {
		icon = "󰹈", ---@type string|false as opposed to the marker only used in nvim, thus nerdfont glyphs are okay
		signHlgroup = "DiagnosticSignInfo", ---@type string|false
		signPriority = 50,
		lineHlgroup = false, ---@type string|false

		nvimSatelliteIntegration = {
			enabled = true,
			hlgroup = "DiagnosticSignInfo",
			icon = "▪",
			leftOfScrollbar = false,
			priority = 40, -- compared to other handlers (diagnostics are 50)
		},
	},

	-- Auto-install a pre-commit hook that prevents commits containing the marker
	-- string. Will not be installed if there is already another pre-commit-hook.
	preCommitHook = {
		enabled = false,
		notifyOnInstall = true,
		hookPath = ".chainsaw", -- relative to git root

		-- Will insert the marker as `%s`. (To block the commit, pre-commit hooks
		-- require a shebang and exit non-zero when marker is found.)
		hookContent = [[#!/bin/sh
			if git grep --fixed-strings --line-number "%s" .; then
				echo
				echo "nvim-chainsaw marker found. Aborting commit."
				exit 1
			fi
		]],

		-- Relevant if you track your nvim-config via git and use a custom marker,
		-- as your config will then always include the marker and falsely trigger
		-- the pre-commit hook.
		notInNvimConfigDir = true,

		-- List of git roots where the hook should not be installed. Supports
		-- globs and `~`. Must match the full directory.
		dontInstallInDirs = {
			-- "~/special-project"
			-- "~/repos/**",
		},
	},

	-- configuration for specific logtypes
	logTypes = {
		emojiLog = {
			emojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },
		},
	},

	-----------------------------------------------------------------------------
	-- see https://github.com/chrisgrieser/nvim-chainsaw/blob/main/lua/chainsaw/config/log-statements-data.lua
	logStatements = require("chainsaw.config.log-statements-data").logStatements,
	supersets = require("chainsaw.config.log-statements-data").supersets,
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
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
	for _, logType in pairs(M.config.logStatements) do
		M.supersetInheritance(logType)
	end

	-- VALIDATE
	local warn = require("chainsaw.utils").warn
	local emojis = M.config.logTypes.emojiLog.emojis
	if not emojis or type(emojis) ~= "table" or #emojis == 0 then
		M.config.logTypes.emojiLog.emojis = defaultConfig.logTypes.emojiLog.emojis
		warn("Config `logtypes.emojiLog.emojis` is not a list of strings. Falling back to defaults.")
	end
	if not M.config.marker or M.config.marker == "" then
		M.config.marker = defaultConfig.marker
		warn("Config `marker` must not be non-empty string. Falling back to default.")
	end

	-- initialize
	require("chainsaw.nvim-debug") -- activates `Chainsaw` global var
	require("chainsaw.visuals.styling").styleExistingLogs()
	require("chainsaw.visuals.satellite-integration")
end

--------------------------------------------------------------------------------
return M
