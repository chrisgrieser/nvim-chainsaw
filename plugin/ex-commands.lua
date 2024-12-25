vim.api.nvim_create_user_command("Chainsaw", function(ctx)
	-- INFO needs to index main file, as commands are made dot-repeatable there
	require("chainsaw")[ctx.args]()
end, {
	nargs = 1,
	complete = function(query)
		local cmds = vim.tbl_keys(require("chainsaw.core.log-commands"))
		return vim.tbl_filter(function(cmd) return cmd:lower():find(query) end, cmds)
	end,
})

