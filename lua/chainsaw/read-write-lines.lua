local M = {}

---@param msg string
local function warn(msg) vim.notify(msg, vim.log.levels.WARN, { title = "Chainsaw" }) end
--------------------------------------------------------------------------------

---append string below current line
---@param logLines string|string[]
---@param varsToInsert string[]
function M.appendLines(logLines, varsToInsert)
	local ln, col = unpack(vim.api.nvim_win_get_cursor(0))
	local indent = vim.api.nvim_get_current_line():match("^%s*")
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
