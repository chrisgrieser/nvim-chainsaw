-- SOURCE printing varname is based on https://stackoverflow.com/a/10459129/22114136
--------------------------------------------------------------------------------

---@param varValue any
function _G.Chainsaw(varValue)
	local varname

	-- varname: Check caller's scope
	-- CAVEAT prints the 1st variable in the caller's scope that has the given value
	for stackLvl = 1, math.huge do
		---@diagnostic disable-next-line: param-type-mismatch spurious diagnostic by nvim-type-check (does not occur with local lua_ls)
		local localName, localValue = debug.getlocal(2, stackLvl, 1)
		if not localName then break end
		if vim.deep_equal(localValue, varValue) then varname = localName end
	end

	-- varnme: Check global scope
	if not varname then
		for globalName, globalValue in pairs(_G) do
			if vim.deep_equal(globalValue, varValue) then varname = globalName end
		end
	end

	-- line number of the print statement
	local caller = debug.getinfo(2, "Sl") -- "S": source, "l": currentline
	local lnum = caller.currentline
	local source = vim.fs.basename(caller.source)

	-- notify, with settings for snacks.nvim/nvim-notify
	local icon = require("chainsaw.config.config").config.visuals.notificationIcon
	local title = varname or "unknown"
	if lnum then title = title .. (" (%s:%d)"):format(source, lnum) end
	if package.loaded["notify"] then title = vim.trim(icon .. " " .. title) end
	vim.notify(
		vim.inspect(varValue),
		vim.log.levels.DEBUG,
		{ title = title, icon = icon, ft = "lua" }
	)
end
