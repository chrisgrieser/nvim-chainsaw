local M = {}
--------------------------------------------------------------------------------

---Most reliable way seems to be to get the indent of the line *after* the
---cursor. If that line is a blank, we look further down. If the next line has
---less indentation than the current line, it is the end of an indentation and
---we return the current indentation instead.
---@return string -- the indent as string
---@nodiscard
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

---@param logType string
---@return string[]|false -- returns false if not configured or invalid
---@nodiscard
local function getTemplateStr(logType)
	local notify = require("chainsaw.utils").notify

	local ft = vim.bo.filetype
	if vim.api.nvim_buf_get_name(0):find("nvim.*%.lua$") then ft = "nvim_lua" end

	local logStatements = require("chainsaw.config").config.logStatements
	local templateStr = logStatements[logType][ft]
	if type(templateStr) == "string" then templateStr = { templateStr } end

	-- GUARD unconfigured filetype
	if not templateStr then
		notify(("There is no configuration for %q in %q."):format(logType, ft), "warn")
		return false
	end

	-- GUARD statement has line breaks
	local hasLineBreaks = vim.iter(templateStr):any(function(line) return line:find("[\r\n]") end)
	if hasLineBreaks then
		local msg = table.concat({
			("%q for %q has line breaks."):format(logType, ft),
			"The nvim-api does not accept line breaks in string when appending text.",
			"Use a list of strings instead, each string representing one line.",
		}, "\n")
		notify(msg, "warn")
		return false
	end

	return templateStr
end

---Prevent nested quotes from making statements invalid.
---example: `var["field"]` would make `console.log("…")` invalid when inserted.
---@param var string
---@param templateLines string[]
---@return string var
---@nodiscard
local function ensureValidQuotesInVar(var, templateLines)
	local template = table.concat(templateLines)
	local quoteInTemplate = template:match('"') or template:match("'")
	local quotesInVar = var:match('"') or var:match("'")
	if quotesInVar and quoteInTemplate and quotesInVar == quoteInTemplate then
		local otherQuote = quotesInVar == "'" and '"' or "'"
		var = var:gsub(quotesInVar, otherQuote)
	end
	return var
end

---@param line string
---@param var string
---@param logtypeSpecific? string
---@return string
---@nodiscard
local function insertPlaceholders(line, var, logtypeSpecific)
	local config = require("chainsaw.config").config

	line = line:gsub("{{%w-}}", function(placeholder)
		if placeholder == "{{marker}}" then return config.marker end
		if placeholder == "{{var}}" then return var end
		if placeholder == "{{lnum}}" then return tostring(vim.api.nvim_win_get_cursor(0)[1]) end
		if placeholder == "{{filename}}" then return vim.fs.basename(vim.api.nvim_buf_get_name(0)) end
		if placeholder == "{{time}}" then return tostring(os.date("%H:%M:%S")) end
		if placeholder == "{{index}}" or placeholder == "{{emoji}}" then
			return assert(logtypeSpecific, "log-type specific parameter is missing.")
		end
		error("Unknown placeholder: " .. placeholder)
	end)
	return line
end

-- DEPRECATION warning
---@param logLines string[]
---@return boolean
---@nodiscard
local function isDeprecatedTemplate(logLines)
	local allLines = table.concat(logLines)
	if allLines:find("%%s") and not allLines:find("{{%w-}}") then
		local msg =
			"The `%s` placeholder is has been replaced with `{{placeholders}}`. See the readme."
		require("chainsaw.utils").notify(msg, "warn")
		return true
	end
	return false
end

--------------------------------------------------------------------------------

---@param logType? string
---@param logtypeSpecific? string
---@return boolean success
function M.insert(logType, logtypeSpecific)
	-- GET LINES
	if not logType then logType = vim.b.chainsawLogType end
	local logLines = getTemplateStr(logType)
	if not logLines then return false end

	-- DEPRECATION
	if isDeprecatedTemplate(logLines) then return false end

	-- run `getVar` only once, since it leaves visual, resulting in a changed result the 2nd time
	local var = require("chainsaw.var-detect").getVar()
	var = ensureValidQuotesInVar(var, logLines)

	-- INSERT LINES
	local ln, col = unpack(vim.api.nvim_win_get_cursor(0))
	local indent = determineIndent() -- using `:normal ==` would break dot-repeatability
	for _, line in pairs(logLines) do
		line = insertPlaceholders(line, var, logtypeSpecific)
		vim.api.nvim_buf_set_lines(0, ln, ln, true, { indent .. line })
		require("chainsaw.highlight").addHighlightToLine(ln)
		ln = ln + 1
	end
	vim.api.nvim_win_set_cursor(0, { ln, col }) -- move to last inserted line

	return true
end

--------------------------------------------------------------------------------
return M
