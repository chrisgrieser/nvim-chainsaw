-- SOURCE printing varname is based on https://stackoverflow.com/a/10459129/22114136
-- CAVEAT prints the 1st variable in the caller's scope that has the given value
--------------------------------------------------------------------------------

---@param varValue any
function _G.Chainsaw(varValue)
	local varname

	-- varname: 1. Check caller's scope (caller = `Chainsaw` log statement)
	for indexOfVars = 1, math.huge do
		local localName, localValue = debug.getlocal(2, indexOfVars)
		if not localName then break end
		if vim.deep_equal(localValue, varValue) then varname = localName end
	end

	-- varname: 2. Check caller's upvalues
	if not varname then
		local callerFunc = debug.getinfo(2, "f").func
		for indexOfUpvalues = 1, math.huge do
			local upName, upValue = debug.getupvalue(callerFunc, indexOfUpvalues)
			if not upName then break end
			if vim.deep_equal(upValue, varValue) then varname = upName end
		end
	end

	-- varnme: 3. Check global scope
	if not varname then
		for globalName, globalValue in pairs(_G) do
			if vim.deep_equal(globalValue, varValue) then varname = globalName end
		end
	end

	-- line number of the caller
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
