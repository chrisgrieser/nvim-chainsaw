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

	-- VARNAME
	local potentialVarnames = {}

	-- 1. caller's scope
	for indexOfVars = 1, math.huge do
		if #potentialVarnames > 1 then break end -- PERF not needed anymore, as we will read source
		local localName, localValue = debug.getlocal(2, indexOfVars)
		if not localName then break end
		if vim.deep_equal(localValue, varValue) then table.insert(potentialVarnames, localName) end
	end

	-- 2. caller's upvalues
	for indexOfUpvalues = 1, math.huge do
		if #potentialVarnames > 1 then break end -- not needed anymore, as we will read source
		local upName, upValue = debug.getupvalue(caller.func, indexOfUpvalues)
		if not upName then break end
		if vim.deep_equal(upValue, varValue) then table.insert(potentialVarnames, upName) end
	end

	-- 3. global scope
	for globalName, globalValue in pairs(_G) do
		if #potentialVarnames > 1 then break end -- not needed anymore, as we will read source
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
			local file, _ = io.open(sourcePath, "r")
			callerLine = file and vim.split(file:read("*a"), "\n")[lnum] or ""
		end

		local varnameInFile = callerLine:match("Chainsaw *%( *([%w_]+).-%)")
		varname = varnameInFile or "unclear"
	end

	-- STRACKTRACE
	-- simple form, only including function names
	local maxLevel = 15
	local separator = " "
	local stack = {}
	for level = 2, maxLevel do
		local info = debug.getinfo(level, "n")
		if not info then break end
		if info.name then table.insert(stack, info.name) end
	end
	-- add as lua comment for de-emphasized highlighting
	local stacktrace = #stack > 0 and "-- " .. table.concat(stack, separator) or ""

	-- NOTIFY
	-- with options for `snacks.nvim` / `nvim-notify`
	local title = varname
	if sourceShort and lnum then title = title .. (" (%s:%d)"):format(sourceShort, lnum) end
	local icon = require("chainsaw.config.config").config.visuals.notificationIcon
	local msg = vim.trim(vim.inspect(varValue) .. "\n" .. stacktrace)
	local level = vim.log.levels.INFO -- below `INFO` not shown with nivm-notify with defaults
	vim.notify(msg, level, { title = title, icon = icon, ft = "lua" })
end
