local M = {}
local ns = vim.api.nvim_create_namespace("chainsaw.markers")
--------------------------------------------------------------------------------

---@param ln number
function M.addStylingToLine(ln)
	local c = require("chainsaw.config.config").config.loglines
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

function M.styleExistingLogs()
	local marker = require("chainsaw.config.config").config.marker
	if marker == "" then return end

	local function setStylingInBuffer(bufnr) ---@param bufnr number
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		for ln, line in ipairs(lines) do
			if line:find(marker, nil, true) then M.addStylingToLine(ln - 1) end
		end
	end

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = vim.api.nvim_create_augroup("chainsaw.highlight", { clear = true }),
		callback = function(ctx) setStylingInBuffer(ctx.buf) end,
	})
	setStylingInBuffer(0) -- initialize
end

--------------------------------------------------------------------------------
return M
