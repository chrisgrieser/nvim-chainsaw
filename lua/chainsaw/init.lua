local version = vim.version()
if version.major == 0 and version.minor < 10 then
	vim.notify(
		'"nvim-chainsaw" requires at least nvim 0.10. Last commit supporting nvim 0.9 is 6e285fc.',
		vim.log.levels.WARN
	)
	return
end

local M = {}
--------------------------------------------------------------------------------

---@param userConfig? Chainsaw.config
function M.setup(userConfig) require("chainsaw.config.config").setup(userConfig) end

vim.api.nvim_create_user_command(
	"Chainsaw",
	-- INFO needs to index this file to make commands dot-repeatable
	function(ctx) M[ctx.args]() end,
	{
		nargs = 1,
		complete = function(query)
			local cmds = vim.tbl_keys(require("chainsaw.core.log-commands"))
			return vim.tbl_filter(function(cmd) return cmd:lower():find(query) end, cmds)
		end,
	}
)

-- DEPRECATION
vim.api.nvim_create_user_command("ChainSaw", function()
	local msg = "`:ChainSaw` is deprecated. Use `:Chainsaw` instead."
	vim.notify(msg, vim.log.levels.WARN)
end, { nargs = "?" })

-- 1. The metatable sends any indexing operation to the `log-commands` module.
-- 2. The `require` is wrapped in code that makes the the action dot-repeatable
-- by setting `operatorfunc`. The subsequent `g@` operation calls the functions
-- itself again, while passing `motion` (see 3.), triggering the `require` to
-- the log-commands module. This results in the `g@` being the last command,
-- which allows `.` to repeat the command stored in `operatorfunc`.
-- Further explanation: https://www.vikasraj.dev/blog/vim-dot-repeat
-- 3. Operators usually expect a motion, but this plugin's commands do not
-- require one. Since we still need a motion to detect whether we are in the
-- initial call or second call, we require a dummy motion. For that, we use `l`,
-- as this motion prevents the cursor from moving.
-- 4. For dot-repeatability to work, it is furthermore necessary to not execute
-- operators in the during the functions called, as this command would be
-- repeated instead. Most notably, this means `vim.cmd.normal` CANNOT be used.
-- 5. The dot-repeatability lines are only triggered in normal mode, since
-- visual mode in vim has no dot-repeatability. Also, the use of `:normal`
-- would result in vim leaving visual mode, breaking mode detection later on.
setmetatable(M, {
	__index = function(_, key)
		local function dotRepeatable(motion, ...)
			if not motion and vim.fn.mode() == "n" then
				vim.o.operatorfunc = "v:lua.require'chainsaw'." .. key
				vim.cmd.normal { "g@l", bang = true }
			else
				vim.b.chainsawLogType = key
				require("chainsaw.core.log-commands")[key](...)
			end
		end
		return dotRepeatable
	end,
})

--------------------------------------------------------------------------------
return M
