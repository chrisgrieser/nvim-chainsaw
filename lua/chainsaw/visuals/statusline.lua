local M = {}
--------------------------------------------------------------------------------

function M.countInBuffer()
	local icon = require("chainsaw.config.config").config.visuals.statuslineIcon

	local ns = vim.api.nvim_create_namespace("chainsaw.markers")
	local extm = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
	local notDeletedExtm = vim.tbl_filter(function(e) return not e[4].invalid end, extm)
	if #notDeletedExtm == 0 then return "" end

	return vim.trim((icon or "") .. " " .. #notDeletedExtm)
end

--------------------------------------------------------------------------------
return M
