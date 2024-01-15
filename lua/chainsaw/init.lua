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
	-- The marker should be a unique string, since `.removeLogs()` will remove
	-- any line with it. Emojis or strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- emojis used for `.beepLog()`
	-- stylua: ignore
	beepEmojis = { "1️⃣ ", "2️⃣ ", "3️⃣ ", "4️⃣ ", "5️⃣ ", "6️⃣ ", "7️⃣ ", "8️⃣ ", "9️⃣ ", "🔟" },

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

	if not vim.b.beepLogIndex then vim.b["beepLogIndex"] = 1 end
	local emoji = config.beepEmojis[vim.b.beepLogIndex]
	vim.b["beepLogIndex"] = vim.b.beepLogIndex + 1

	u.appendLines(logLines, { config.marker, emoji })
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

	-- reeet these logs
	vim.b["beepLogIndex"] = nil
	vim.b["timelogStart"] = nil
end

--------------------------------------------------------------------------------
return M
