local M = {}

local rw = require("chainsaw.read-write-lines")
local getVar = require("chainsaw.var-detect").getVar

local function normal(cmdStr) vim.cmd.normal { cmdStr, bang = true } end

--------------------------------------------------------------------------------

function M.messageLog()
	local config = require("chainsaw.config").config
	local logLines = rw.getTemplateStr("messageLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker })

	-- goto insert mode at correct location
	normal('f";')
	vim.defer_fn(vim.cmd.startinsert, 1)
end

function M.variableLog()
	local config = require("chainsaw.config").config
	local varname = getVar()
	local logLines = rw.getTemplateStr("variableLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker, varname, varname })
end

function M.objectLog()
	local config = require("chainsaw.config").config
	local varname = getVar()
	local logLines = rw.getTemplateStr("objectLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker, varname, varname })
end

function M.stacktraceLog()
	local config = require("chainsaw.config").config
	local logLines = rw.getTemplateStr("stacktraceLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker })
end

function M.assertLog()
	local config = require("chainsaw.config").config
	local varname = getVar()
	local logLines = rw.getTemplateStr("assertLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { varname, config.marker, varname })
	normal("f,") -- goto the comma to edit the condition
end

function M.beepLog()
	local config = require("chainsaw.config").config
	local logLines = rw.getTemplateStr("beepLog", config.logStatements)
	if not logLines then return end

	-- select the first emoji with the least number of occurrences, ensuring that
	-- we will get as many different emojis as possible
	local emojiToUse = { emoji = "", count = math.huge }
	local bufferText = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	for _, emoji in ipairs(config.beepEmojis) do
		local _, count = bufferText:gsub(emoji, "")
		if count < emojiToUse.count then emojiToUse = { emoji = emoji, count = count } end
	end

	rw.appendLines(logLines, { config.marker, emojiToUse.emoji })
end

function M.timeLog()
	local config = require("chainsaw.config").config
	if vim.b.timeLogStart == nil then vim.b.timeLogStart = true end

	local startOrStop = vim.b.timeLogStart and "timeLogStart" or "timeLogStop"
	local logLines = rw.getTemplateStr(startOrStop, config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker })

	vim.b.timeLogStart = not vim.b.timeLogStart
end

function M.debugLog()
	local config = require("chainsaw.config").config
	local logLines = rw.getTemplateStr("debugLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker })
end

function M.removeLogs()
	local config = require("chainsaw.config").config
	local numOfLinesBefore = vim.api.nvim_buf_line_count(0)

	-- GUARD
	if config.marker == "" then
		vim.notify("No marker set.", vim.log.levels.ERROR, { title = "Chainsaw" })
		return
	end

	-- escape for vim regex, in case `[]()` are used in the marker
	local toRemove = config.marker:gsub("([%[%]()])", "\\%1")
	local cursorPos = vim.api.nvim_win_get_cursor(0)
	vim.cmd(("silent global/%s/delete _"):format(toRemove))
	vim.api.nvim_win_set_cursor(0, cursorPos)
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
return M
