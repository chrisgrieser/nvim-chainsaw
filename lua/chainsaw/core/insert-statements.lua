local M = {}
local u = require("chainsaw.utils")
--------------------------------------------------------------------------------

---Most reliable way seems to be to get the indent of the line *after* the
---cursor. If that line is a blank, we look further down. If the next line has
---less indentation than the current line, it is the end of an indentation and
---we return the current indentation instead.
---@param startLnum number
---@return string -- the indent as string
---@nodiscard
local function determineIndent(startLnum)
	local function getLine(lnum) return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] end
	local function isBlank(lnum) return getLine(lnum):find("^%s*$") ~= nil end

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
	local ft = u.getFiletype()

	local logStatements = require("chainsaw.config.config").config.logStatements
	local templateStr = logStatements[logType][ft]
	if type(templateStr) == "string" then templateStr = { templateStr } end

	-- GUARD unconfigured filetype
	if not templateStr then
		local msg = ("There is no configuration for %q in %q."):format(logType, ft)
		u.warn(msg)
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
		u.warn(msg)
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

---@return number
---@nodiscard
local function shiftInInsertLocation()
	local parserExists, node = pcall(vim.treesitter.get_node)
	if not node or not parserExists then return 0 end

	local ft = require("chainsaw.utils").getFiletype()
	local shiftCalcFunc = require("chainsaw.config.smart-insert-location").ftConfig[ft]
	if not shiftCalcFunc then return 0 end
	local shiftLines = shiftCalcFunc(node) or 0
	return shiftLines
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

	-- INSERT PLACEHOLDERS
	-- run `getVar` only once, since it leaves visual, resulting in a changed result the 2nd time
	local var = require("chainsaw.core.determine-var").getVar()
	var = ensureValidQuotesInVar(var, logLines)
	local marker = require("chainsaw.config.config").config.marker
	local errorMsg
	logLines = vim.tbl_map(function(line)
		line = line:gsub("{{%w-}}", function(placeholder)
			if placeholder == "{{marker}}" then
				return marker
			elseif placeholder == "{{var}}" then
				if var == "" then errorMsg = "Could not find a variable to insert." end
				return var
			elseif placeholder == "{{filename}}" then
				return vim.fs.basename(vim.api.nvim_buf_get_name(0))
			elseif placeholder == "{{time}}" then
				return tostring(os.date("%H:%M:%S"))
			elseif placeholder == "{{index}}" or placeholder == "{{emoji}}" then
				if not logtypeSpecific then errorMsg = "This log type does not use " .. placeholder end
				return logtypeSpecific
			end
			-- these are dependent of the line number shift and thus inserted later
			if placeholder == "{{lnum}}" or placeholder == "{{insert}}" then return end
			errorMsg = "Unknown placeholder: " .. placeholder
		end)
		return line
	end, logLines)
	if errorMsg then
		u.warn(errorMsg)
		return false
	end

	-- INSERT LINES
	local ln, col = unpack(vim.api.nvim_win_get_cursor(0))
	ln = ln + shiftInInsertLocation()
	assert(ln <= vim.api.nvim_buf_line_count(0), "Insert location is past the end of the buffer.")
	local indent = determineIndent(ln) -- using `:normal ==` would break dot-repeatability
	for _, line in pairs(logLines) do
		-- populate `{{lnum}}` with line of log statement, not line of var https://github.com/chrisgrieser/nvim-chainsaw/pull/37#issuecomment-3381582599
		line = line:gsub("{{lnum}}", tostring(ln))
		vim.api.nvim_buf_set_lines(0, ln, ln, true, { indent .. line })
		if line:find(marker, nil, true) then
			require("chainsaw.visuals.styling").addStylingToLine(ln)
		end
		ln = ln + 1
	end
	vim.api.nvim_win_set_cursor(0, { ln, col }) -- move to last inserted line

	-- Handle `{{insert}}` in the last line
	local curLine = vim.api.nvim_get_current_line()
	local insertStart, insertEnd = curLine:find("{{insert}}")
	if insertStart and insertEnd then
		local updatedLine = curLine:sub(1, insertStart - 1) .. curLine:sub(insertEnd + 1)
		vim.api.nvim_set_current_line(updatedLine)
		vim.api.nvim_win_set_cursor(0, { ln, insertStart - 1 })
		vim.schedule(vim.cmd.startinsert)
	end

	require("chainsaw.pre-commit-hook").install()
	return true
end

--------------------------------------------------------------------------------
return M
