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
		statuslineIcon = "󰹈",
		notificationIcon = "󰹈",
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

	-- auto-install a pre-commit hook that prevents commits containing the marker
	-- string. Note that this will override git's `core.hookPath`, disabling any
	-- other hooks you have.
	preCommitHook = {
		enabled = false,
		notifyOnInstall = true,
		hookPath = ".chainsaw", -- relative to git root

		-- Will insert the marker as `%s`. (Pre-commit hooks eequires a shebang.
		-- It should exit non-zero when marker is found, to block the commit.)
		hookContent = [[#!/bin/sh
			grep --recursive --fixed-strings --line-number "%s" . || exit 0
			echo
			echo "nvim-chainsaw marker found in commit. Aborting commit."
			exit 1
		]],

		-- do not install the hook, if the repo already has a different pre-commit hook
		noHookOverride = true,

		-- List of directories where the hook will not be installed if they are
		-- the git root. Supports globs and `~`. Must *fully* match the directory.
		dontInstallInDirs = {
			-- "~/special-project"
			-- "~/repos/**",

			-- If you track your nvim-config via git, and use a custom marker, you
			-- should add it to this list, since it will contain the marker string:
			-- "~/.config/nvim",
		},
	},

	-- configuration for specific logtypes
	logTypes = {
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

	require("chainsaw.nvim-debug") -- actives `Chainsaw` global var

	-- DEPRECATION 2024-12-02
	if M.config.logEmojis then ---@diagnostic disable-line: undefined-field
		local msg = "Config `logEmojis` is deprecated. Use `logTypes.emojiLog.emojis` instead."
		warn(msg)
	end

	-- DEPRECATION
	if M.config.logtypes then ---@diagnostic disable-line: undefined-field
		local msg = "Config `logtypes` is deprecated. Use `logTypes` instead."
		warn(msg)
	end

	-- DEPRECATION
	if M.config.logHighlightGroup then ---@diagnostic disable-line: undefined-field
		local msg = "Config `logHighlightGroup` is deprecated. Use `visuals.lineHlgroup` instead."
		warn(msg)
	end

	-- DEPRECATION
	if M.config.loglines then ---@diagnostic disable-line: undefined-field
		warn("Config `loglines` is deprecated. Use `visuals` instead.")
	end

	-- VALIDATE
	local emojis = M.config.logTypes.emojiLog.emojis
	if not emojis or type(emojis) ~= "table" or #emojis == 0 then
		M.config.logTypes.emojiLog.emojis = defaultConfig.logTypes.emojiLog.emojis
		warn("Config `logtypes.emojiLog.emojis` is not a list of strings. Falling back to defaults.")
	end
	if not M.config.marker or M.config.marker == "" then
		M.config.marker = defaultConfig.marker
		warn("Config `marker` must not be non-empty string. Falling back to default.")
		Chainsaw(warn) -- 🪚
	end

	-- initialize
	require("chainsaw.visuals.styling").styleExistingLogs()
	require("chainsaw.visuals.satellite-integration")
end

--------------------------------------------------------------------------------
return M
