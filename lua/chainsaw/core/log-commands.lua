local insertStatements = require("chainsaw.core.insert-statements").insert

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
	assertLog = insertStatements,
	messageLog = insertStatements,
}

function M.emojiLog()
	local conf = require("chainsaw.config.config").config.logTypes.emojiLog

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
	local numOfLinesBefore = vim.api.nvim_buf_line_count(0)
	local mode = vim.fn.mode()
	local bufLines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- normal mode: whole buffer
	-- visual mode: selected lines
	local startLnum, endLnum
	if mode == "n" then
		startLnum = 1
		endLnum = #bufLines
	elseif mode:find("[Vv]") then
		startLnum = vim.fn.getpos("v")[2]
		endLnum = vim.fn.getpos(".")[2]
		if startLnum > endLnum then
			startLnum, endLnum = endLnum, startLnum
		end
		vim.cmd.normal { mode, bang = true } -- leave visual mode
	end

	-- Remove lines
	-- (Deleting lines instead of overriding whole buffer to preserve marks, folds, etc.)
	for lnum = endLnum, startLnum, -1 do
		if bufLines[lnum]:find(marker, nil, true) then
			vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, {})
		end
	end

	-- notify on number of lines removed
	local linesRemoved = numOfLinesBefore - vim.api.nvim_buf_line_count(0)
	local pluralS = linesRemoved == 1 and "" or "s"
	local msg = ("Removed %d line%s."):format(linesRemoved, pluralS)
	require("chainsaw.utils").info(msg)

	-- reset
	vim.b.timelogStart = nil
	vim.b.timeLogIndex = nil
end

--------------------------------------------------------------------------------
return M
