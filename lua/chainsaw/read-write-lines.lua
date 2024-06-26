local M = {}

---@param msg string
local function warn(msg) vim.notify(msg, vim.log.levels.WARN, { title = "ChainSaw" }) end
--------------------------------------------------------------------------------

---most reliable way seems to be to get the indent of the line *after* the
---cursor. If that line is a blank, we look further down. If the next line has
---less indentation than the current line, it is the end of an indentation and
---we return the current indentation instead.
---@return string -- the indent as string
local function determineIndent()
	local function getLine(lnum) return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] end
	local function isBlank(lnum) return getLine(lnum):find("^%s*$") ~= nil end

	local startLnum = vim.api.nvim_win_get_cursor(0)[1]
	local lastLnumInBuf = vim.api.nvim_buf_line_count(0)
	local currentIndent = getLine(startLnum):match("^%s*")

	if startLnum == lastLnumInBuf then return currentIndent end
	local lnum = startLnum
	repeat
		lnum = lnum + 1
	until lnum >= lastLnumInBuf or not isBlank(lnum)

	local nextLineIndent = getLine(lnum):match("^%s*")
	local lineIsEndOfIndentation = #nextLineIndent < #currentIndent
	if lineIsEndOfIndentation then return currentIndent end
	return nextLineIndent
end

--------------------------------------------------------------------------------

---append string below current line
---@param logLines string|string[]
---@param varsToInsert string[]
function M.appendLines(logLines, varsToInsert)
	local ln, col = unpack(vim.api.nvim_win_get_cursor(0))
	if type(logLines) == "string" then logLines = { logLines } end

	-- Prevent nested quotes making logs invalid.
	-- example: `var["field"]` would make `console.log("…")` invalid when inserted.
	local quotesInVar
	for _, var in pairs(varsToInsert) do
		quotesInVar = var:match("'") or var:match('"')
		if quotesInVar then break end
	end
	if quotesInVar then
		local repl = quotesInVar == "'" and '"' or "'"
		logLines = vim.tbl_map(function(line) return line:gsub(quotesInVar, repl) end, logLines)
	end

	-- INFO we cannot use `:normal ==` to auto-indent the lines, because it using
	-- a normal command messes up dot-repeatability. Thus, we have to determine
	-- the indent manually ourselves.
	local indent = determineIndent()

	-- insert all lines
	for _, line in pairs(logLines) do
		local toInsert = indent .. line:format(unpack(varsToInsert))
		vim.api.nvim_buf_set_lines(0, ln, ln, true, { toInsert })
		ln = ln + 1
	end

	-- move cursor down to last inserted line
	vim.api.nvim_win_set_cursor(0, { ln, col })
end

---@param logType string
---@param logsData logStatementData
---@return string|string[]|false returns false if not configured or invalid
---@nodiscard
function M.getTemplateStr(logType, logsData)
	local ft = vim.bo.filetype
	if vim.api.nvim_buf_get_name(0):find("nvim.*%.lua$") then ft = "nvim_lua" end
	local templateStr = logsData[logType][ft]

	-- GUARD unconfigured filetype
	if not templateStr then
		warn(("There is no configuration for %q in %q."):format(logType, ft))
		return false
	end

	-- GUARD template has line breaks, which are not accepted by nvim-api
	local strArr = type(templateStr) == "string" and { templateStr } or templateStr
	---@cast strArr string[]
	for _, line in pairs(strArr) do
		if line:find("[\r\n]") then
			local msg = {
				("Template for %q in %q has line breaks."):format(logType, ft),
				"The nvim-api does not accept line breaks in string when appending text.",
				"Use a list of strings instead, each string representing one line.",
			}
			warn(table.concat(msg, "\n"))
			return false
		end
	end

	return templateStr
end

--------------------------------------------------------------------------------
return M
