-- load treesitter-highlighting for the `Chainsaw` global var from this plugin's
-- `queries/lua/highlights.scm`, manually, in case user lazy-loads this plugin
if vim.bo.filetype == "lua" then pcall(vim.treesitter.start) end
--------------------------------------------------------------------------------

local prevNotif = {}

---@diagnostic disable-next-line: duplicate-set-field spurious diagnostic when added to `lazydev`
function _G.Chainsaw(varValue)
	if not package.loaded["snacks"] and not package.loaded["notify"] then
		local msg = "The `Chainsaw` function requires either `snacks.nvim` or `notify.nvim`."
		vim.notify(msg, vim.log.levels.ERROR)
		return
	end

	-- IDENTIFY CALLER IN STACK
	-- caller = where the `Chainsaw` function is called
	-- similar https://github.com/folke/snacks.nvim/blob/main/lua/snacks/debug.lua
	local stacklvl = 1
	local caller = debug.getinfo(stacklvl, "Slfn") -- S:source, l:currentline, f:function, n:name

	-- find the `Chainsaw` function in the stack
	while true do
		stacklvl = stacklvl + 1
		local info = debug.getinfo(stacklvl, "Slfn")
		-- Excluding the name "Chainsaw" used their own wrapper around `Chainsaw`
		if info and info.source ~= caller.source and info.name ~= "Chainsaw" then
			caller = info
			break
		end
	end

	local lnum = caller.currentline
	local sourceAbspath = caller.short_src
	local sourceFile = vim.fs.basename(sourceAbspath)
	-----------------------------------------------------------------------------

	-- VARNAME
	-- varname identification based on https://stackoverflow.com/a/10459129/22114136
	local potentialVarnames = {}

	-- 1. caller's scope
	for indexOfVars = 1, math.huge do
		if #potentialVarnames > 1 then break end -- PERF not needed anymore, as we will use callerline
		local localName, localValue = debug.getlocal(stacklvl, indexOfVars)
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
		local buffer = vim.iter(vim.fn.getbufinfo())
			:find(function(b) return b.name == sourceAbspath end)
		if buffer then
			callerLine = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
		else
			local file, _ = io.open(sourceAbspath, "r")
			callerLine = file and vim.split(file:read("*a"), "\n")[lnum] or ""
		end

		local varnameInFile = callerLine:match("Chainsaw *(%b())")
		varname = varnameInFile and vim.trim(varnameInFile:sub(2, -2)) or "unknown"
	end

	-----------------------------------------------------------------------------

	-- NOTIFY
	-- with options for `snacks.nvim` / `nvim-notify`
	local title = varname
	if lnum then title = title .. (" (%s:%d)"):format(sourceFile, lnum) end
	local icon = require("chainsaw.config.config").config.visuals.icon or ""
	local msg = vim.trim(vim.inspect(varValue))
	local level = vim.log.levels.INFO -- below `INFO` not shown with nivm-notify with defaults
	local opts = { title = title, icon = icon, ft = "lua" }

	-- notify-spam protection: if the same notification is shown repeatedly,
	-- replace the icon with a counter instead of displaying duplicates
	if prevNotif.title == title and prevNotif.msg == msg then
		prevNotif.count = (prevNotif.count or 1) + 1
		-- "tortoise shell brackets" for distinguishability from regular brackets
		opts.icon = opts.icon .. (" %dx"):format(prevNotif.count)
		opts.id = prevNotif.id -- replace for `snacks.nvim`
		opts.replace = prevNotif.isOpen and prevNotif.id or nil -- replace for `nvim-notify`
	else
		prevNotif = {} -- = reset
	end
	if package.loaded["notify"] then
		-- HACK prevent replacement error when using `replace` for a non-open notification
		opts.on_open = function() prevNotif.isOpen = true end
		opts.on_close = function() prevNotif.isOpen = false end
	end

	local notif = vim.notify(msg, level, opts) --[[@as { id: number }]]
	-- in certain race conditions related to plugin load order, still uses
	-- nvim-core's `vim.notify` which does not return anything, thus need to fall
	-- back to id of `-1`
	prevNotif.id = type(notif) == "table" and notif.id or -1

	prevNotif.title = title
	prevNotif.msg = msg
end
