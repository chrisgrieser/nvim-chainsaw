local insertStatements = require("chainsaw.core.insert-statements").insert

---@return boolean success
local function moveCursorToQuotes()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local curLine = vim.api.nvim_get_current_line()
	local _, _end = curLine:find([[".*"]])
	if not _end then
		_, _end = curLine:find([['.*']])
	end
	if not _end then return false end
	vim.api.nvim_win_set_cursor(0, { lnum, _end - 1 })
	return true
end

--------------------------------------------------------------------------------

-- not using metatable-__index, as the logtype-names are needed for suggestions
-- for the `:Chainsaw` command
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
	moveCursorToQuotes() -- easier to edit assertion msg
end

function M.emojiLog()
	local conf = require("chainsaw.config.config").config.logtypes.emojiLog
	assert(conf.emojis, "Config `logtypes.emojiLog.emojis` is not a list of strings.")

	-- randomize emoji order
	local emojis = vim.deepcopy(conf.emojis)
	for i = #emojis, 2, -1 do
		local j = math.random(i)
		emojis[i], emojis[j] = emojis[j], emojis[i]
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
	success = moveCursorToQuotes()
	if success then vim.defer_fn(vim.cmd.startinsert, 1) end
end

function M.timeLog()
	if vim.b.timeLogStart == nil then vim.b.timeLogStart = true end
	if vim.b.timeLogIndex == nil then vim.b.timeLogIndex = 1 end

	local startOrStop = vim.b.timeLogStart and "timeLogStart" or "timeLogStop"
	local success = insertStatements(startOrStop, vim.b.timeLogIndex)
	if not success then return end

	if vim.b.timeLogStart then
		vim.b.timeLogStart = false
	else
		vim.b.timeLogIndex = vim.b.timeLogIndex + 1
		vim.b.timeLogStart = true
	end
end

--------------------------------------------------------------------------------

function M.removeLogs()
	local marker = require("chainsaw.config.config").config.marker
	assert(marker ~= "", "Marker may not be empty.")
	local numOfLinesBefore = vim.api.nvim_buf_line_count(0)

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
	local msg = ("Removed %d lines."):format(linesRemoved)
	if linesRemoved == 1 then msg = msg:sub(1, -3) .. "." end -- 1 = singular
	require("chainsaw.utils").info(msg)

	-- reset
	vim.b.timelogStart = nil
end

--------------------------------------------------------------------------------
return M
