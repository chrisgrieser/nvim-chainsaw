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
			vim.api.nvim_buf_get_text(0, startLn - 1, startCol, endLn - 1, endCol + 1, {})[1]
		return selection
	end

	-- cursor-word
	-- (extended with `.` to try to include the correct variable in most languages)
	local previousOpt = vim.opt.iskeyword:get()
	vim.opt.iskeyword:append(".")
	local cword = vim.fn.expand("<cword>")
	vim.opt.iskeyword = previousOpt

	-- smart variable detection, fallback to cword if
	-- * filetype has no configuration for it
	-- * no treesitter parser or no node under cursor
	-- * node is has line breaks
	local parserExists, node = pcall(vim.treesitter.get_node)
	if not node or not parserExists then return cword end

	local ft = require("chainsaw.utils").getFiletype()
	local detectorFunc = require("chainsaw.config.smart-var-detect").ftConfig[ft]
	if not detectorFunc then return cword end

	if detectorFunc then node = detectorFunc(node) end
	if not node then return cword end

	local nodeText = vim.treesitter.get_node_text(node, 0)
	if nodeText:find("[\r\n]") then return cword end

	return nodeText
end

--------------------------------------------------------------------------------
return M
