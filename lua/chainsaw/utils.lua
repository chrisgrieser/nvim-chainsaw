local M = {}
--------------------------------------------------------------------------------

local function normal(cmdStr) vim.cmd.normal { cmdStr, bang = true } end

---in normal mode, returns word under cursor, in visual mode, returns selection
---@return string
---@nodiscard
function M.getVar()
	local isVisualMode = vim.fn.mode():find("[Vv]")
	if isVisualMode then
		local prevReg = vim.fn.getreg("z")
		normal('"zy')
		local varname = vim.fn.getreg("z"):gsub('"', '//"')
		vim.fn.setreg("z", prevReg)
		return varname
	else
		if not (vim.treesitter.get_node and vim.treesitter.get_node()) then
			return vim.fn.expand("<cword>")
		end
		local node = vim.treesitter.get_node() ---@cast node TSNode -- checked in condition above
		return vim.treesitter.get_node_text(node, 0)
	end
end

---append string below current line
---@param logLines string|string[]
---@param varsToInsert string[]
function M.appendLines(logLines, varsToInsert)
	local ln = vim.api.nvim_win_get_cursor(0)[1]

	local indentBasedFts = { "python", "yaml", "elm" }
	local isIndentBased = vim.tbl_contains(indentBasedFts, vim.bo.ft)
	local indent = isIndentBased and vim.api.nvim_get_current_line():match("^%s*") or ""
	local action = isIndentBased and "j" or "j=="

	if type(logLines) == "string" then logLines = { logLines } end
	for _, line in pairs(logLines) do
		local toInsert = indent .. line:format(unpack(varsToInsert))
		vim.api.nvim_buf_set_lines(0, ln, ln, true, { toInsert })
		normal(action)
		ln = ln + 1
	end
end

---get template string, if it does not exist, return nil
---@param logType string
---@param logsData logStatementData
---@return string|string[]|nil
---@nodiscard
function M.getTemplateStr(logType, logsData)
	local ft = vim.bo.filetype
	if vim.api.nvim_buf_get_name(0):find("nvim.*%.lua$") then ft = "nvim_lua" end
	local templateStr = logsData[logType][ft]
	if not templateStr then
		local msg = ("%s does not support %s yet."):format(logType, ft)
		vim.notify(msg, vim.log.levels.WARN, { title = "Chainsaw" })
	end
	return templateStr
end


--------------------------------------------------------------------------------
return M
