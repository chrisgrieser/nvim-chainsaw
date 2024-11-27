local M = {}
--------------------------------------------------------------------------------

---@return string
---@nodiscard
function M.getVar()
	-- visual mode -> return selection
	local mode = vim.fn.mode()
	if mode:find("[Vv]") then
		vim.cmd.normal { mode, bang = true } -- leave visual mode so `<`> mark sare set
		local startLn, startCol = unpack(vim.api.nvim_buf_get_mark(0, "<"))
		local endLn, endCol = unpack(vim.api.nvim_buf_get_mark(0, ">"))
		local selection =
			vim.api.nvim_buf_get_text(0, startLn - 1, startCol, endLn - 1, endCol + 1, {})
		local text = table.concat(selection, "\n"):gsub('"', '//"')
		return text
	end

	-- nvim prior to v0.9 OR no node under cursor -> return cword
	if not vim.treesitter.get_node then return vim.fn.expand("<cword>") end
	local parserExists, node = pcall(vim.treesitter.get_node)
	if not node or not parserExists then return vim.fn.expand("<cword>") end

	-- smart variable detection
	local detectorFunc = require("chainsaw.config.smart-var-detect").ftConfig[vim.bo.filetype]
	if detectorFunc then node = detectorFunc(node) end

	-- fallback to cword if node has no parent
	if not node then return vim.fn.expand("<cword>") end

	-- fallback to cword if node multiline
	local nodeText = vim.treesitter.get_node_text(node, 0)
	if nodeText:find("[\r\n]") then return vim.fn.expand("<cword>") end

	return nodeText
end

--------------------------------------------------------------------------------
return M
