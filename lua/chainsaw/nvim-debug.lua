-- SOURCE the varname identification is based on https://stackoverflow.com/a/10459129/22114136
--------------------------------------------------------------------------------

local previous = {}

---@diagnostic disable-next-line: duplicate-set-field spurious diagnostic when added to `lazydev`
function _G.Chainsaw(varValue)
	-- caller = the `Chainsaw` log statement
	local caller = debug.getinfo(2, "Slf") -- S:source l:currentline f:function
	local lnum = caller.currentline
	local sourcePath = caller.source:gsub("^@", "")
	local sourceShort = vim.fs.basename(sourcePath)
	if sourceShort == ":source (no file)" then sourceShort = "source" end
	-----------------------------------------------------------------------------

	-- VARNAME
	local potentialVarnames = {}

	-- 1. caller's scope
	for indexOfVars = 1, math.huge do
		if #potentialVarnames > 1 then break end -- PERF not needed anymore, as we will use callerline
		local localName, localValue = debug.getlocal(2, indexOfVars)
		if not localName then break end
		if vim.deep_equal(localValue, varValue) then table.insert(potentialVarnames, localName) end
	end

	-- 2. caller's upvalues
	for indexOfUpvalues = 1, math.huge do
		if #potentialVarnames > 1 then break end -- not needed anymore, as we will use callerline
		local upName, upValue = debug.getupvalue(caller.func, indexOfUpvalues)
		if not upName then break end
		if vim.deep_equal(upValue, varValue) then table.insert(potentialVarnames, upName) end
	end

	-- 3. global scope
	for globalName, globalValue in pairs(_G) do
		if #potentialVarnames > 1 then break end -- not needed anymore, as we will use callerline
		if vim.deep_equal(globalValue, varValue) then table.insert(potentialVarnames, globalName) end
	end

	local varname
	if #potentialVarnames == 1 then
		varname = potentialVarnames[1]
	else
		-- CALLERLINE HACK
		-- if there are multiple or no variables with the same value, we need to
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

		local varnameInFile = callerLine:match("Chainsaw *(%b())")
		varname = varnameInFile and vim.trim(varnameInFile:sub(2, -2)) or "unknown"
	end

	-----------------------------------------------------------------------------

	-- NOTIFY
	-- with options for `snacks.nvim` / `nvim-notify`
	local title = varname
	if sourceShort and lnum then title = title .. (" (%s:%d)"):format(sourceShort, lnum) end
	local icon = require("chainsaw.config.config").config.visuals.notificationIcon
	local msg = vim.trim(vim.inspect(varValue))
	local level = vim.log.levels.INFO -- below `INFO` not shown with nivm-notify with defaults
	local opts = { title = title, icon = icon, ft = "lua" }

	-- Track notifications: if the same notification is shown repeatedly, replace
	-- the icon with a counter instead of displaying duplicates notifications
	if previous.title == title and previous.msg == msg then
		previous.count = (previous.count or 1) + 1
		opts.icon = ("[%d]"):format(previous.count)
		opts.id = previous.id -- replace for `snacks.nvim`
		opts.replace = previous.isOpen and previous.id or nil -- replace for `nvim-notify`
	else
		previous = {} -- = reset
	end
	if package.loaded["notify"] then
		-- HACK prevent replacement error when using `replace` for a non-open notification
		opts.on_open = function() previous.isOpen = true end
		opts.on_close = function() previous.isOpen = false end
	end

	local id = vim.notify(msg, level, opts)
	previous.id, previous.title, previous.msg = id, title, msg
end
