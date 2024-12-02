local M = {}
--------------------------------------------------------------------------------

---@param msg string
---@param level "error"|"warn"|"info"|"trace"|"debug"
local function notify(msg, level)
	local icon = require("chainsaw.config.config").config.visuals.notificationIcon
	vim.notify(msg, vim.log.levels[level:upper()], { title = "chainsaw", icon = icon })
end

---@param msg string
function M.warn(msg) notify(msg, "warn") end

---@param msg string
function M.info(msg) notify(msg, "info") end

---@return string
---@nodiscard
function M.getFiletype()
	local ft = vim.bo.filetype
	if vim.api.nvim_buf_get_name(0):find("nvim.*%.lua$") then ft = "nvim_lua" end
	return ft
end

--------------------------------------------------------------------------------
return M
