local u = require("chainsaw.utils")
local getVar = require("chainsaw.variable-identification").getVar

local M = {}
local function normal(cmdStr) vim.cmd.normal { cmdStr, bang = true } end
--------------------------------------------------------------------------------

---@class (exact) pluginConfig
---@field marker string
---@field beepEmojis string[]
---@field logStatements logStatementData

---@type pluginConfig
local defaultConfig = {
	-- The marker should be a unique string, since `.removeLogs()` will remove
	-- any line with it. Emojis or strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- emojis used for `.beepLog()`
	beepEmojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },

	logStatements = require("chainsaw.log-statements-data"),
}

local config = defaultConfig -- in case user does not call `setup`

---@param newConfig? pluginConfig
function M.setup(newConfig) config = vim.tbl_deep_extend("force", defaultConfig, newConfig or {}) end

--------------------------------------------------------------------------------

function M.messageLog()
	local logLines = u.getTemplateStr("messageLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker })

	-- goto insert mode at correct location
	normal('f";')
	vim.cmd.startinsert()
end

function M.variableLog()
	local varname = getVar()
	local logLines = u.getTemplateStr("variableLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker, varname, varname })
end

function M.objectLog()
	local varname = getVar()
	local logLines = u.getTemplateStr("objectLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker, varname, varname })
end

function M.stacktraceLog()
	local logLines = u.getTemplateStr("stacktraceLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker })
end

function M.assertLog()
	local varname = getVar()
	local logLines = u.getTemplateStr("assertLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { varname, config.marker, varname })
	normal("f,") -- goto the comma to edit the condition
end

function M.beepLog()
	local logLines = u.getTemplateStr("beepLog", config.logStatements)
	if not logLines then return end

	if not vim.b.beepLogIdx then vim.b["beepLogIdx"] = 0 end
	-- `math.fmod()` is lua's modulus
	vim.b["beepLogIdx"] = math.fmod(vim.b.beepLogIdx, #config.beepEmojis) + 1
	local emoji = config.beepEmojis[vim.b.beepLogIdx]

	u.appendLines(logLines, { config.marker, emoji })
end

function M.timeLog()
	if vim.b.timeLogStart == nil then vim.b.timeLogStart = true end

	local startOrStop = vim.b.timeLogStart and "timeLogStart" or "timeLogStop"
	local logLines = u.getTemplateStr(startOrStop, config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker })

	vim.b.timeLogStart = not vim.b.timeLogStart
end

function M.debugLog()
	local logLines = u.getTemplateStr("debugLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker })
end

function M.removeLogs()
	local numOfLinesBefore = vim.api.nvim_buf_line_count(0)

	-- GUARD
	if config.marker == "" then
		vim.notify("No marker set.", vim.log.levels.ERROR, { title = "Chainsaw" })
		return
	end

	-- escape for vim regex, in case `[]()` are used in the marker
	local toRemove = config.marker:gsub("([%[%]()])", "\\%1")
	vim.cmd(("silent global/%s/delete"):format(toRemove))
	vim.cmd.nohlsearch()

	-- notify on number of lines removed
	local linesRemoved = numOfLinesBefore - vim.api.nvim_buf_line_count(0)
	local msg = ("Removed %s lines."):format(linesRemoved)
	if linesRemoved == 1 then msg = msg:sub(1, -3) .. "." end -- 1 = singular
	vim.notify(msg, vim.log.levels.INFO, { title = "Chainsaw" })

	-- reset
	vim.b.timelogStart = nil
end

--------------------------------------------------------------------------------

-- CREATE USER COMMANDS
local commandsExceptSetup = vim.tbl_filter(function(cmd) return cmd ~= "setup" end, vim.tbl_keys(M))

vim.api.nvim_create_user_command(
	"ChainSaw",
	function(opts) M[opts.args]() end,
	{ nargs = 1, complete = function() return commandsExceptSetup end }
)

--------------------------------------------------------------------------------
return M
