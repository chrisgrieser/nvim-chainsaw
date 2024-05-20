local M = {}
--------------------------------------------------------------------------------

local function normal(cmdStr) vim.cmd.normal { cmdStr, bang = true } end

---@return string
---@nodiscard
function M.getVar()
	-- visual mode -> return selection
	local isVisualMode = vim.fn.mode():find("[Vv]")
	if isVisualMode then
		local prevReg = vim.fn.getreg("z")
		normal('"zy')
		local varname = vim.fn.getreg("z"):gsub('"', '//"')
		vim.fn.setreg("z", prevReg)
		return varname
	end

	-- nvim prior to v0.9 OR no node under cursor -> return cword
	if not vim.treesitter.get_node then return vim.fn.expand("<cword>") end
	local parserExists, node = pcall(vim.treesitter.get_node)
	if not node or not parserExists then return vim.fn.expand("<cword>") end

	-----------------------------------------------------------------------------

	-- smart variable identification: for fields, use parent node
	local ft = vim.bo.filetype
	if ft == "lua" then
		local cursorOnDot = node:type() == "dot_index_expression"
		local cursorOnField = node:parent():type() == "dot_index_expression"
			and node:prev_named_sibling()
		if cursorOnDot then
			node = node:parent()
		elseif cursorOnField then
			node = node:parent():parent()
		end
	elseif ft == "javascript" or ft == "typescript" or ft == "typescriptreact" then
		local cursorOnField = node:type() == "property_identifier"
		if cursorOnField then node = node:parent() end
	elseif ft == "python" then
		local cursorOnField = node:type():find("^string_")
		if cursorOnField then node = node:parent():parent() end
	end

	-- GUARD on invalid node, fall back to cword
	---@cast node TSNode
	local nodeText = vim.treesitter.get_node_text(node, 0)
	if nodeText:find("[\r\n]") then return vim.fn.expand("<cword>") end
	return nodeText
end

--------------------------------------------------------------------------------
return M
