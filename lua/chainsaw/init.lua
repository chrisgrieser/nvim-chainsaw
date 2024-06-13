local M = {}
--------------------------------------------------------------------------------

---@param newConfig? pluginConfig
function M.setup(newConfig) require("chainsaw.config").setup(newConfig) end

vim.api.nvim_create_user_command(
	"ChainSaw",
	function(opts) M[opts.args]() end,
	{ nargs = 1, complete = function() return vim.tbl_keys(require("chainsaw.log-commands")) end }
)

setmetatable(M, {
	__index = function(_, key)
		return function(...) require("chainsaw.log-commands")[key](...) end
	end,
})

--------------------------------------------------------------------------------
return M
