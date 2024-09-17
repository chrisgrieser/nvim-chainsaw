---@alias logStatementData table<string, table<string, string|string[]>>

--------------------------------------------------------------------------------
-- INFO
-- 1. The strings may not include linebreaks. If you want to use multi-line log
-- statements, use a list of strings instead, each string representing one line.
-- 2. All `%s` are replaced with the respective `_placeholders`.
--------------------------------------------------------------------------------

---@type logStatementData
local M = {
	variableLog = {
		_placeholders = { "marker", "var", "var" },
		lua = 'print("%s %s: " .. tostring(%s))',
		nvim_lua = 'vim.notify("%s %s: " .. tostring(%s))', -- not using `print` due to https://github.com/folke/noice.nvim/issues/556
		python = 'print(f"%s {%s = }")',
		javascript = 'console.log("%s %s:", %s);',
		sh = 'echo "%s %s: $%s" >&2',
		applescript = 'log "%s %s:" & %s',
		css = "outline: 2px solid red !important; /* %s */",
		rust = 'println!("{} {}: {:?}", "%s", "%s", %s);',
		ruby = 'puts "%s %s: #{%s}"',
	},
	objectLog = {
		_placeholders = { "marker", "var", "var" },
		nvim_lua = 'vim.notify("%s %s: " .. vim.inspect(%s))', -- no built-in method in normal lua
		javascript = 'console.log("%s %s:", JSON.stringify(%s))',
		ruby = 'puts "%s %s: #{%s.inspect}"',
	},
	assertLog = {
		_placeholders = { "var", "marker", "var" },
		lua = 'assert(%s, "%s %s")',
		python = 'assert %s, "%s %s"',
		typescript = 'console.assert(%s, "%s %s");',
	},
	typeLog = {
		_placeholders = { "marker", "var", "var" },
		lua = 'print("%s %s: type is " .. type(%s))',
		nvim_lua = 'vim.notify("%s %s: type is " .. type(%s))',
		javascript = 'console.log("%s %s: type is " + typeof %s)',
		python = 'print(f"%s %s: {type(%s)}")',
	},
	beepLog = {
		_placeholders = { "marker", "beepEmoji" },
		lua = 'print("%s beep %s")',
		nvim_lua = 'vim.notify("%s beep %s")',
		python = 'print("%s beep %s")',
		javascript = 'console.log("%s beep %s");',
		sh = 'echo "%s beep %s" >&2',
		applescript = 'log "%s beep %s"',
		ruby = 'puts "%s beep %s"',
	},
	sound = { -- NOTE system bell commands requires program to run in a terminal supporting it
		_placeholders = { "marker" },
		sh = 'printf "\\a" # %s', -- system bell
		python = 'print("\\a")  # %s', -- system bell
		applescript = "beep -- %s",
		-- javascript = 'console.log("\\u0007"); // %s', -- system bell
		javascript = 'new Audio("data:audio/wav;base64,UklGRl9vT19XQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YU"+Array(800).join("200")).play()',
	},
	messageLog = {
		_placeholders = { "marker" },
		lua = 'print("%s ")',
		nvim_lua = 'vim.notify("%s ")',
		python = 'print("%s ")',
		javascript = 'console.log("%s ");',
		sh = 'echo "%s " >&2',
		applescript = 'log "%s "',
		rust = 'println!("{} ", "%s");',
		ruby = 'puts "%s "',
	},
	stacktraceLog = {
		_placeholders = { "marker" },
		lua = 'print(debug.traceback("%s"))', -- `debug.traceback` already prepends "stacktrace"
		nvim_lua = 'vim.notify(debug.traceback("%s"))',
		zsh = 'print "%s stacktrack: $funcfiletrace $funcstack"',
		bash = "print '%s stacktrace: ' ; caller 0",
		javascript = 'console.log("%s stacktrace: ", new Error()?.stack?.replaceAll("\\n", " "));', -- not all JS engines support console.trace()
		typescript = 'console.trace("%s stacktrace: ");',
	},
	debugLog = {
		_placeholders = { "marker" },
		javascript = "debugger; // %s",
		python = "breakpoint()  # %s",
		sh = {
			"set -exuo pipefail # %s", -- https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
			"set +exuo pipefail # %s", -- re-enable, so it does not disturb stuff from interactive shell
		},
	},
	clearLog = {
		_placeholders = { "marker" },
		javascript = "console.clear(); // %s",
		python = "clear()  # %s",
		sh = "clear # %s",
	},
	timeLogStart = {
		_placeholders = { "marker" },
		lua = "local timelogStart = os.clock() -- %s",
		python = "local timelogStart = time.perf_counter()  # %s",
		javascript = "const timelogStart = Date.now(); // %s", -- not all JS engines support console.time
		typescript = 'console.time("%s");',
		sh = "timelogStart=$(date +%%s) # %s",
		ruby = "timelog_start = Process.clock_gettime(Process::CLOCK_MONOTONIC) # %s",
	},
	timeLogStop = {
		_placeholders = { "marker" },
		lua = {
			"local durationSecs = os.clock() - timelogStart -- %s",
			'print(("%s: %%.3fs"):format(durationSecs))',
		},
		nvim_lua = {
			"local durationSecs = os.clock() - timelogStart -- %s",
			'vim.notify(("%s: %%.3fs"):format(durationSecs))',
		},
		python = {
			"durationSecs = round(time.perf_counter() - timelogStart, 3)  # %s",
			'print(f"%s: {durationSecs}s")',
		},
		javascript = {
			"const durationSecs = (Date.now() - timelogStart) / 1000; // %s",
			"console.log(`%s: ${durationSecs}s`);",
		},
		typescript = 'console.timeEnd("%s");',
		sh = {
			"durationSecs=$(($(date +%%s) - timelogStart))",
			'echo "%s ${durationSecs}s" >&2',
		},
		ruby = {
			"duration_secs = Process.clock_gettime(Process::CLOCK_MONOTONIC) - timelog_start # %s",
			'puts "%s: #{duration_secs}s"',
		},
	},
}

--------------------------------------------------------------------------------
-- SUPERSETS
local logTypes = vim.tbl_keys(M)

-- JS supersets inherit from `typescript`, and in turn `typescript` form
-- `javascript`, if it set itself.
local jsSupersets = { "typescriptreact", "javascriptreact", "vue", "svelte" }
for _, logType in ipairs(logTypes) do
	if not M[logType].typescript then M[logType].typescript = M[logType].javascript end
	for _, lang in ipairs(jsSupersets) do
		M[logType][lang] = M[logType].typescript
	end
end

-- shell supersets inherit from `sh`, if they have no config of their own.
local shellSupersets = { "bash", "zsh", "fish", "nu" }
for _, logType in ipairs(logTypes) do
	for _, lang in ipairs(shellSupersets) do
		if not M[logType][lang] then M[logType][lang] = M[logType].sh end
	end
end

-- CSS supersets inherit from `css`, if they have no config of their own.
local cssSupersets = { "scss", "less", "sass" }
for _, logType in ipairs(logTypes) do
	for _, lang in ipairs(cssSupersets) do
		if not M[logType][lang] then M[logType][lang] = M[logType].css end
	end
end

-- `nvim-lua` inherits from `lua`, if it has no config of its own.
for _, logType in ipairs(logTypes) do
	if not M[logType].nvim_lua and M[logType].lua then M[logType].nvim_lua = M[logType].lua end
end

--------------------------------------------------------------------------------
return M
