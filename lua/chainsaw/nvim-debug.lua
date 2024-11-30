-- SOURCE
-- 1. printing varname: https://stackoverflow.com/a/10459129/22114136
-- 2. printing callor line: https://github.com/folke/snacks.nvim/blob/3c1849a09b9618cbc49eed337f0a302394ef049b/lua/snacks/debug.lua#L13-L32
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

	-- line number of print statement
	local caller = debug.getinfo(1, "S")
	for stackLvl = 2, 10 do
		local info = debug.getinfo(stackLvl, "S")
		if
			info
			and info.source ~= caller.source
			and info.what ~= "C"
			and info.source ~= "lua"
			and info.source ~= "@" .. (vim.env.MYVIMRC or "")
		then
			caller = info
			break
		end
	end
	local lnum = caller.currentline

	-- notify, with settings for snacks.nvim/nvim-notify
	local icon = require("chainsaw.config.config").config.visuals.notificationIcon
	local title = varname or "unknown"
	if lnum then title = title .. " (L" .. lnum .. ")" end
	if package.loaded["notify"] then title = vim.trim(icon .. " " .. title) end
	vim.notify(
		vim.inspect(varValue),
		vim.log.levels.DEBUG,
		{ title = title, icon = icon, ft = "lua" }
	)
end
