---@alias logStatementData table<string, table<string, string|string[]?>>

--------------------------------------------------------------------------------
-- INFO
-- 1. The strings may not include linebreaks. If you want to use multi-line log
-- statements, use a list of strings instead, each string representing one line.
-- 2. All `%s` are replaced with the respective `_placeholders`.
-- 3. see `config.lua` for superset-languages inheritance (e.g, `scss`
-- inheriting log statemetns from `css`.)
--------------------------------------------------------------------------------

---@type logStatementData
local M = {
	variableLog = {
		_placeholders = { "marker", "var", "var" },
		-- 1. not using `print` due `noice.nvim` https://github.com/folke/noice.nvim/issues/556
		-- 2. using `ft = "lua"` activates highlighting for `snacks.nvim`
		nvim_lua = 'vim.notify("%s %s: " .. vim.inspect(%s), nil, { ft = "lua" })',
		lua = 'print("%s %s: " .. tostring(%s))',
		python = 'print(f"%s {%s = }")',
		javascript = 'console.log("%s %s:", %s);',
		sh = 'echo "%s %s: $%s" >&2', -- `>&2` sends to stderr only
		applescript = 'log "%s %s:" & %s',
		css = "outline: 2px solid red !important; /* %s */",
		rust = 'println!("{} {}: {:?}", "%s", "%s", %s);',
		ruby = 'puts "%s %s: #{%s}"',
	},
	objectLog = {
		_placeholders = { "marker", "var", "var" },
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
	emojiLog = {
		_placeholders = { "marker", "special" }, -- special = emoji
		lua = 'print("%s %s")',
		nvim_lua = 'vim.notify("%s %s")',
		python = 'print("%s %s")',
		javascript = 'console.log("%s %s");',
		sh = 'echo "%s %s" >&2',
		applescript = 'log "%s %s"',
		ruby = 'puts "%s %s"',
	},
	sound = { -- NOTE terminal bell commands requires program to run in a terminal supporting it
		_placeholders = { "marker" },
		sh = 'printf "\\a" # %s', -- terminal bell
		python = 'print("\\a")  # %s', -- terminal bell
		applescript = "beep -- %s", -- system sound

		-- system sound
		javascript = 'new Audio("data:audio/wav;base64,UklGRl9vT19XQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YU"+Array(800).join("200")).play()',
		-- terminal bell
		-- javascript = 'console.log("\\u0007"); // %s',

		-- system sound (macOS only)
		lua = jit.os == "OSX" and [[os.execute("osascript -e 'beep'") -- %s]] or nil,
		nvim_lua = jit.os == "OSX" and 'vim.system({"osascript", "-e", "beep"}) -- %s' or nil,
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
		_placeholders = { "special", "marker" }, -- special = index
		lua = "local timelogStart%s = os.clock() -- %s",
		python = "local timelog_start_%s = time.perf_counter()  # %s",
		javascript = "const timelogStart%s = Date.now(); // %s", -- not all JS engines support console.time
		typescript = 'console.time("#%s %s");', -- string needs to be identical to `console.timeEnd`
		sh = "timelog_start_%s=$(date +%%s) # %s",
		ruby = "timelog_start_%s = Process.clock_gettime(Process::CLOCK_MONOTONIC) # %s",
	},
	timeLogStop = {
		_placeholders = { "special", "marker", "special" }, -- special = index
		lua = 'print(("#%s %s: %%.3fs"):format(os.clock() - timelogStart%s))',
		nvim_lua = 'vim.notify(("#%s %s: %%.3fs"):format(os.clock() - timelogStart%s))',
		python = 'print(f"#%s %s: {round(time.perf_counter() - timelog_start_%s, 3)}s")',
		javascript = "console.log(`#%s %s: ${(Date.now() - timelogStart%s) / 1000}s`);",
		typescript = 'console.timeEnd("#%s %s");',
		sh = 'echo "#%s %s $(($(date +%%s) - timelog_start_%s))s" >&2',
		ruby = 'puts "#%s %s: #{Process.clock_gettime(Process::CLOCK_MONOTONIC) - timelog_start_%s}s"',
	},
}

--------------------------------------------------------------------------------
return M
