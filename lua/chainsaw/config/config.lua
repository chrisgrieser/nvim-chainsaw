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
		icon = "󰹈", -- as opposed to marker only used in nvim, thus nerdfont icons are okay
		signHlgroup = "DiagnosticSignInfo",
		lineHlgroup = false,

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

		-- Will insert the marker as `%s`. (Pre-commit hooks requires a shebang
		-- and exit non-zero when marker is found to block the commit.)
		hookContent = [[#!/bin/sh
			if git grep --fixed-strings --line-number "%s" .; then
				echo
				echo "nvim-chainsaw marker found. Aborting commit."
				exit 1
			fi
		]],

		-- If you track your nvim-config via git, and use a custom marker, you
		-- should add it to this list, since your config will then always include
		-- a marker, thus always falsely triggering the pre-commit hook.
		notInNvimConfigDir = true,

		-- List of directories where the hook should not be installed if they are
		-- the git root. Supports globs and `~`. Must *fully* match the directory.
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
	local warn = require("chainsaw.utils").warn

	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})

	for _, logType in pairs(M.config.logStatements) do
		M.supersetInheritance(logType)
	end

	require("chainsaw.nvim-debug") -- actives `Chainsaw` global var

	---@diagnostic disable: undefined-field
	-- DEPRECATION 2024-12-02
	if M.config.logEmojis then
		local msg = "Config `logEmojis` is deprecated. Use `logTypes.emojiLog.emojis` instead."
		warn(msg)
	end
	if M.config.logtypes then
		local msg = "Config `logtypes` is deprecated. Use `logTypes` instead."
		warn(msg)
	end
	if M.config.logHighlightGroup then
		local msg = "Config `logHighlightGroup` is deprecated. Use `visuals.lineHlgroup` instead."
		warn(msg)
	end
	if M.config.loglines then warn("Config `loglines` is deprecated. Use `visuals` instead.") end
	-- DEPRECATION (2024-12-18)
	if M.config.visuals.sign then
		warn("Config `visuals.sign` is deprecated. Use `visuals.icon` instead.")
	end
	---@diagnostic enable: undefined-field

	-- VALIDATE
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
	require("chainsaw.visuals.styling").styleExistingLogs()
	require("chainsaw.visuals.satellite-integration")
end

--------------------------------------------------------------------------------
return M
