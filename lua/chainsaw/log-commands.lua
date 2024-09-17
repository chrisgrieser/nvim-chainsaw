local insertStatements = require("chainsaw.insert-statements").insert
local notify = require("chainsaw.utils").notify

---@param pattern string
---@param where "start"|"end"
---@return boolean success
local function moveCursorToPattern(pattern, where)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local start, _end = vim.api.nvim_get_current_line():find(pattern)
	local location = where == "end" and _end or start
	if location then
		vim.api.nvim_win_set_cursor(0, { lnum, location - 1 })
		return true
	end
	return false
end

--------------------------------------------------------------------------------

-- not using metatable-__index, as the logtype-names are needed for suggestions 
-- for the `:ChainSaw` command
local M = {
	variableLog = insertStatements,
	objectLog = insertStatements,
	typeLog = insertStatements,
	stacktraceLog = insertStatements,
	debugLog = insertStatements,
	clearLog = insertStatements,
	sound = insertStatements,
}

function M.assertLog()
	local success = insertStatements()
	if not success then return end
	moveCursorToPattern(".,", "start") -- easier to edit the assertion condition
end

function M.beepLog()
	local emojis = require("chainsaw.config").config.beepEmojis
	if not emojis or type(emojis) ~= "table" or #emojis == 0 then
		notify("`beepEmojis` is not set.", "error")
		return
	end

	-- select the first emoji with the least number of occurrences, ensuring that
	-- we will get as many different emojis as possible
	local emojiToUse = { emoji = "", count = math.huge }
	local bufferText = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
	for _, emoji in ipairs(emojis) do
		local _, count = bufferText:gsub(emoji, "")
		if count < emojiToUse.count then emojiToUse = { emoji = emoji, count = count } end
	end
	insertStatements(nil, emojiToUse.emoji)
end

function M.messageLog()
	local success = insertStatements()
	if not success then return end

	-- goto insert mode at correct location to enter message
	success = moveCursorToPattern('".*"', "end") or moveCursorToPattern("'.*'", "end")
	if success then vim.defer_fn(vim.cmd.startinsert, 1) end
end

function M.timeLog()
	if vim.b.timeLogStart == nil then vim.b.timeLogStart = true end

	local startOrStop = vim.b.timeLogStart and "timeLogStart" or "timeLogStop"
	local success = insertStatements(startOrStop)

	if success then vim.b.timeLogStart = not vim.b.timeLogStart end
end

--------------------------------------------------------------------------------

function M.removeLogs()
	local marker = require("chainsaw.config").config.marker
	local numOfLinesBefore = vim.api.nvim_buf_line_count(0)

	-- GUARD
	if marker == "" then
		notify("No marker set.", "error")
		return
	end

	-- Remove lines. Deleting individual lines instead of rewriting the whole
	-- buffer to preserve marks, folds, and undos.
	local bufLines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for i = #bufLines, 1, -1 do
		if bufLines[i]:find(marker, nil, true) then
			vim.api.nvim_buf_set_lines(0, i - 1, i, false, {})
		end
	end

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
