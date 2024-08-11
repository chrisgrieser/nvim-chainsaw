local M = {}
local ns = vim.api.nvim_create_namespace("chainsaw.highlight")
--------------------------------------------------------------------------------

---@param ln number
function M.addHighlightToLine(ln)
	local hlGroup = require("chainsaw.config").config.logHighlightGroup
	if not hlGroup then return end

	vim.api.nvim_buf_set_extmark(0, ns, ln, 1, {
		line_hl_group = hlGroup,
		invalidate = true, -- deletes the extmark if the line is deleted
		undo_restore = true, -- makes undo restore those
	})
end

--------------------------------------------------------------------------------

function M.highlightExistingLogs()
	local function highlightInBuffer(bufnr) ---@param bufnr number
		local marker = require("chainsaw.config").config.marker

		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		for ln, line in ipairs(lines) do
			if line:find(marker, nil, true) then M.addHighlightToLine(ln - 1) end
		end
	end

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = vim.api.nvim_create_augroup("chainsaw.highlight", { clear = true }),
		callback = function(ctx) highlightInBuffer(ctx.buf) end,
	})
	highlightInBuffer(0) -- initialize
end

--------------------------------------------------------------------------------
return M
