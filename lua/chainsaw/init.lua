local u = require("chainsaw.utils")

local M = {}
local function normal(cmdStr) vim.cmd.normal { cmdStr, bang = true } end
--------------------------------------------------------------------------------

---@class (exact) pluginConfig
---@field marker string
---@field beepEmojis string[]
---@field logStatements logStatementData

---@type pluginConfig
local defaultConfig = {
	-- should be a short, unique string (.removeLogs() will remove any line with it)
	marker = "🪚",
	-- to differentiate between beepLog statements
	beepEmojis = { "🤖", "👽", "👾", "💣" },
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
	normal('f";') -- goto insert mode at correct location
	vim.cmd.startinsert()
end

function M.variableLog()
	local varname = u.getVar()
	local logLines = u.getTemplateStr("variableLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker, varname, varname })
end

function M.objectLog()
	local varname = u.getVar()
	local logLines = u.getTemplateStr("objectLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker, varname, varname })
end

function M.assertLog()
	local varname = u.getVar()
	local logLines = u.getTemplateStr("assertLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { varname, config.marker, varname })
	normal("f,") -- goto the comma to edit the condition
end

---adds simple "beep" log statement to check whether conditionals have been triggered
function M.beepLog()
	local logLines = u.getTemplateStr("beepLog", config.logStatements)
	if not logLines then return end
	local randomEmoji = config.beepEmojis[math.random(1, #config.beepEmojis)]
	u.appendLines(logLines, { config.marker, randomEmoji })
end

function M.timeLog()
	if vim.b.timeLogStart == nil then vim.b["timeLogStart"] = true end

	local startOrStop = vim.b.timeLogStart and "timeLogStart" or "timeLogStop"
	local logLines = u.getTemplateStr(startOrStop, config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker })

	vim.b["timeLogStart"] = not vim.b.timeLogStart
end

-- simple debugger statement
function M.debugLog()
	local logLines = u.getTemplateStr("debugLog", config.logStatements)
	if not logLines then return end
	u.appendLines(logLines, { config.marker })
end

---Remove all log statements in the current buffer
function M.removeLogs()
	local numOfLinesBefore = vim.api.nvim_buf_line_count(0)

	-- escape for vim regex, in case `[]()` are used in the marker
	local toRemove = config.marker:gsub("([%[%]()])", "\\%1")
	vim.cmd(("silent g/%s/d"):format(toRemove))
	vim.cmd.nohlsearch()

	local linesRemoved = numOfLinesBefore - vim.api.nvim_buf_line_count(0)
	local msg = ("Removed %s lines."):format(linesRemoved)
	if linesRemoved == 1 then msg = msg:sub(1, -3) .. "." end -- 1 = singular
	vim.notify(msg, vim.log.levels.INFO, { title = "Chainsaw" })

	vim.b["timelogStart"] = true -- ensure next timelog insert start-statement
end

--------------------------------------------------------------------------------
return M
