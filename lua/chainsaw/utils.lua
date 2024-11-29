local M = {}
--------------------------------------------------------------------------------

---@param msg string
function M.warn(msg)
	local marker = require("chainsaw.config.config").config.marker
	-- `3` to account for emojis/nerdfont that have a width of `2`
	local icon = vim.api.nvim_strwidth(marker) < 3 and marker or nil
	vim.notify(msg, vim.log.levels.WARN, { title = "chainsaw", icon = icon })
end

---@param msg string
function M.info(msg)
	local marker = require("chainsaw.config.config").config.marker
	local icon = vim.api.nvim_strwidth(marker) < 3 and marker or nil
	vim.notify(msg, vim.log.levels.INFO, { title = "chainsaw", icon = icon })
end

---@return string
---@nodiscard
function M.getFiletype()
	local ft = vim.bo.filetype
	if vim.api.nvim_buf_get_name(0):find("nvim.*%.lua$") then ft = "nvim_lua" end
	return ft
end

--------------------------------------------------------------------------------
return M
