-- SOURCE the varname identification is based on https://stackoverflow.com/a/10459129/22114136
--------------------------------------------------------------------------------

---@diagnostic disable-next-line: duplicate-set-field spurious diagnostic when added to `lazydev`
function _G.Chainsaw(varValue)
	-- caller = the `Chainsaw` log statement
	local caller = debug.getinfo(2, "Slf") -- "S": source "l": currentline "f": function
	local lnum = caller.currentline
	local sourcePath = caller.source:gsub("^@", "")
	local sourceShort = vim.fs.basename(sourcePath)
	if sourceShort == ":source (no file)" then sourceShort = "source" end
	-----------------------------------------------------------------------------

	local potentialVarnames = {}

	-- 1. caller's scope
	for indexOfVars = 1, math.huge do
		local localName, localValue = debug.getlocal(2, indexOfVars)
		if not localName then break end
		if vim.deep_equal(localValue, varValue) then table.insert(potentialVarnames, localName) end
	end

	-- 2. caller's upvalues
	for indexOfUpvalues = 1, math.huge do
		local upName, upValue = debug.getupvalue(caller.func, indexOfUpvalues)
		if not upName then break end
		if vim.deep_equal(upValue, varValue) then table.insert(potentialVarnames, upName) end
	end

	-- 3. global scope
	for globalName, globalValue in pairs(_G) do
		if vim.deep_equal(globalValue, varValue) then table.insert(potentialVarnames, globalName) end
	end

	local varname
	if #potentialVarnames == 0 then
		varname = "unknown"
	elseif #potentialVarnames == 1 then
		varname = potentialVarnames[1]
	else
		-- HACK if there are multiple variables with the same value, we need to
		-- resort to manually reading the line at the source file to ensure we got
		-- the right one
		local callerLine

		-- PERF if source file is open, read the buffer, otherwise read the file
		local buffer = vim.iter(vim.fn.getbufinfo()):find(function(b) return b.name == sourcePath end)
		if buffer then
			callerLine = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
		else
			local file, err = io.open(sourcePath, "r")
			assert(file, err) -- file should exist since reported by `debug.getinfo`
			callerLine = vim.split(file:read("*a"), "\n")[lnum]
		end

		local varnameInFile = callerLine:match("Chainsaw *%( *([%w_]+).-%)")
		local likelyName = vim.iter(potentialVarnames)
			:find(function(name) return name == varnameInFile end)
		varname = likelyName or "ambiguous_var"
	end
	local title = varname

	-----------------------------------------------------------------------------
	-- notify, with options for `snacks.nvim` / `nvim-notify`
	local icon = require("chainsaw.config.config").config.visuals.notificationIcon
	if sourceShort and lnum then title = title .. (" (%s:%d)"):format(sourceShort, lnum) end
	if package.loaded["notify"] then title = vim.trim(icon .. " " .. title) end
	vim.notify(
		vim.inspect(varValue),
		vim.log.levels.DEBUG,
		{ title = title, icon = icon, ft = "lua" }
	)
end
