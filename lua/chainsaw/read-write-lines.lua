local M = {}

---@param msg string
local function warn(msg) vim.notify(msg, vim.log.levels.WARN, { title = "Chainsaw" }) end
--------------------------------------------------------------------------------

---append string below current line
---@param logLines string|string[]
---@param varsToInsert string[]
function M.appendLines(logLines, varsToInsert)
	local ln = vim.api.nvim_win_get_cursor(0)[1]
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

	-- ensure correct indentation
	local indentBasedFts = { "python", "yaml", "elm" }
	local isIndentBased = vim.tbl_contains(indentBasedFts, vim.bo.ft)
	local indent = isIndentBased and vim.api.nvim_get_current_line():match("^%s*") or ""
	local action = isIndentBased and "j" or "j=="

	-- insert all the lines
	for _, line in pairs(logLines) do
		local toInsert = indent .. line:format(unpack(varsToInsert))
		vim.api.nvim_buf_set_lines(0, ln, ln, true, { toInsert })
		normal(action)
		ln = ln + 1
	end
end

---@param msg string
local function warnNotify(msg) vim.notify(msg, vim.log.levels.WARN, { title = "Chainsaw" }) end

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
