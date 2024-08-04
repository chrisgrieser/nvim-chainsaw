local M = {}

local appendLines = require("chainsaw.append-lines").append

---@param cmdStr string
local function normal(cmdStr) vim.cmd.normal { cmdStr, bang = true } end

---@return string
local function getMarker() return require("chainsaw.config").config.marker end

--------------------------------------------------------------------------------

function M.variableLog() appendLines() end

function M.objectLog() appendLines() end

function M.assertLog()
	local success = appendLines()
	if success then normal("f,") end -- goto the comma to edit the condition
end

function M.beepLog()
	local config = require("chainsaw.config").config

	-- select the first emoji with the least number of occurrences, ensuring that
	-- we will get as many different emojis as possible
	local emojiToUse = { emoji = "", count = math.huge }
	local bufferText = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	for _, emoji in ipairs(config.beepEmojis) do
		local _, count = bufferText:gsub(emoji, "")
		if count < emojiToUse.count then emojiToUse = { emoji = emoji, count = count } end
	end
	appendLines(nil, emojiToUse.emoji)
end

function M.messageLog()
	local success = appendLines(nil)
	if success then
		-- goto insert mode at correct location
		normal('f";')
		vim.defer_fn(vim.cmd.startinsert, 1)
	end
end

function M.timeLog()
	if vim.b.timeLogStart == nil then vim.b.timeLogStart = true end

	local startOrStop = vim.b.timeLogStart and "timeLogStart" or "timeLogStop"
	local success = appendLines(startOrStop)

	if success then vim.b.timeLogStart = not vim.b.timeLogStart end
end

function M.stacktraceLog() appendLines() end

function M.debugLog() appendLines() end

function M.clearLog() appendLines() end

--------------------------------------------------------------------------------

function M.removeLogs()
	local marker = getMarker()
	local numOfLinesBefore = vim.api.nvim_buf_line_count(0)
	local notify = require("chainsaw.utils").notify

	-- GUARD
	if marker == "" then
		notify("No marker set.", "error")
		return
	end

	-- escape for vim regex, in case `[]()` are used in the marker
	local toRemove = marker:gsub("([%[%]()])", "\\%1")
	local cursorPos = vim.api.nvim_win_get_cursor(0)
	vim.cmd(("silent global/%s/delete _"):format(toRemove))
	vim.api.nvim_win_set_cursor(0, cursorPos)
	vim.cmd.nohlsearch()

	-- notify on number of lines removed
	local linesRemoved = numOfLinesBefore - vim.api.nvim_buf_line_count(0)
	local msg = ("Removed %s lines."):format(linesRemoved)
	if linesRemoved == 1 then msg = msg:sub(1, -3) .. "." end -- 1 = singular
	notify(msg)

	-- reset
	vim.b.timelogStart = nil
end

--------------------------------------------------------------------------------
return M
