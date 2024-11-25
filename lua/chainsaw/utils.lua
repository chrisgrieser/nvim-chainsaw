local M = {}
--------------------------------------------------------------------------------

---@param msg string
function M.warn(msg)
	local marker = require("chainsaw.config").config.marker
	local icon = vim.api.nvim_strwidth(marker) < 2 and marker or nil
	vim.notify(msg, vim.log.levels.WARN, { title = "chainsaw", icon = icon })
end

---@param msg string
function M.info(msg)
	local marker = require("chainsaw.config").config.marker
	local icon = vim.api.nvim_strwidth(marker) < 2 and marker or nil
	vim.notify(msg, vim.log.levels.INFO, { title = "chainsaw", icon = icon })
end

--------------------------------------------------------------------------------
return M
