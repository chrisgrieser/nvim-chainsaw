local M = {}
local ns = vim.api.nvim_create_namespace("chainsaw.highlight")
--------------------------------------------------------------------------------

---@param ln number
function M.addHighlightToLine(ln)
	local c = require("chainsaw.config").config.loglines
	local lineHlgroup = (c.lineHlgroup ~= "" and c.lineHlgroup ~= false) and c.lineHlgroup or nil
	local sign = (c.sign ~= "" and c.sign ~= false) and c.sign or nil
	local signHlgroup = (c.signHlgroup ~= "" and c.signHlgroup ~= false) and c.signHlgroup or nil

	vim.api.nvim_buf_set_extmark(0, ns, ln, 1, {
		line_hl_group = lineHlgroup,
		sign_text = sign,
		sign_hl_group = signHlgroup,
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
