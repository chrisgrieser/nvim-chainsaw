---@alias logStatementData table<string, table<string, string|string[]?>>

--------------------------------------------------------------------------------
-- INFO
-- 1. The strings may not include linebreaks. If you want to use multi-line log
-- statements, use a list of strings instead, each string representing one line.
-- 2. Use `{{placerholder}}` to insert vars, marker, etc.
-- 3. see `config.lua` for superset-languages inheritance 
-- (e.g, `typescript` inheriting log statements from `javascript`.)
--------------------------------------------------------------------------------

---@type logStatementData
local M = {
	variableLog = {
		nvim_lua = 'vim.notify(vim.inspect({{var}}), nil, { title = "{{marker}} {{var}}", ft = "lua" })',
		lua = 'print("{{marker}} {{var}}: " .. tostring({{var}}))',
		python = 'print(f"%s {%s = }")',
		javascript = 'console.log("{{marker}} {{var}}:", {{var}});',
		sh = 'echo "{{marker}} {{var}}: ${{var}}" >&2', -- `>&2` sends to stderr only
		applescript = 'log "{{marker}} {{var}}:" & {{var}}',
		css = "outline: 2px solid red !important; /* {{marker}} */",
		rust = 'println!("{} {}: {:?}", "{{marker}}", "{{var}}", {{var}});',
		ruby = 'puts "{{marker}} {{var}}: #{{{var}}}"',
	},
	objectLog = {
		javascript = 'console.log("{{marker}} {{var}}:", JSON.stringify({{var}}))',
		ruby = 'puts "{{marker}} {{var}}: #{{{var}}.inspect}"',
	},
	assertLog = {
		lua = 'assert({{var}}, "{{marker}} {{var}}")',
		python = 'assert {{var}}, "{{marker}} {{var}}"',
		typescript = 'console.assert({{var}}, "{{marker}} {{var}}");',
	},
	typeLog = {
		lua = 'print("{{marker}} {{var}}: type is " .. type({{var}}))',
		nvim_lua = 'vim.notify("{{marker}} {{var}}: type is " .. type({{var}}))',
		javascript = 'console.log("{{marker}} {{var}}: type is " + typeof {{var}})',
		python = 'print(f"{{marker}} {{var}}: {type({{var}})}")',
	},
	emojiLog = {
		lua = 'print("{{marker}} {{emoji}}")',
		nvim_lua = 'vim.notify("{{marker}} {{emoji}}")',
		python = 'print("{{marker}} {{emoji}}")',
		javascript = 'console.log("{{marker}} {{emoji}}");',
		sh = 'echo "{{marker}} {{emoji}}" >&2',
		applescript = 'log "{{marker}} {{emoji}}"',
		ruby = 'puts "{{marker}} {{emoji}}"',
	},
	sound = { -- NOTE terminal bell commands requires program to run in a terminal supporting it
		sh = 'printf "\\a" # {{marker}}', -- terminal bell
		python = 'print("\\a")  # {{marker}}', -- terminal bell
		applescript = "beep -- {{marker}}", -- system sound

		-- system sound
		javascript = 'new Audio("data:audio/wav;base64,UklGRl9vT19XQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YU"+Array(800).join("200")).play(); // {{marker}}',
		-- terminal bell
		-- javascript = 'console.log("\\u0007"); // {{marker}}',

		-- system sound (macOS only)
		lua = jit.os == "OSX" and [[os.execute("osascript -e 'beep'") -- {{marker}}]] or nil,
		nvim_lua = jit.os == "OSX" and 'vim.system({"osascript", "-e", "beep"}) -- {{marker}}' or nil,
	},
	messageLog = {
		lua = 'print("{{marker}} ")',
		nvim_lua = 'vim.notify("{{marker}} ")',
		python = 'print("{{marker}} ")',
		javascript = 'console.log("{{marker}} ");',
		sh = 'echo "{{marker}} " >&2',
		applescript = 'log "{{marker}} "',
		rust = 'println!("{} ", "{{marker}}");',
		ruby = 'puts "{{marker}} "',
	},
	stacktraceLog = {
		lua = 'print(debug.traceback("{{marker}}"))', -- `debug.traceback` already prepends "stacktrace"
		nvim_lua = 'vim.notify(debug.traceback("{{marker}}"))',
		zsh = 'print "{{marker}} stacktrack: $funcfiletrace $funcstack"',
		bash = "print '{{marker}} stacktrace: ' ; caller 0",
		javascript = 'console.log("{{marker}} stacktrace: ", new Error()?.stack?.replaceAll("\\n", " "));', -- not all JS engines support console.trace()
		typescript = 'console.trace("{{marker}} stacktrace: ");',
	},
	debugLog = {
		javascript = "debugger; // {{marker}}",
		python = "breakpoint()  # {{marker}}",
		sh = {
			"set -exuo pipefail # {{marker}}", -- https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
			"set +exuo pipefail # {{marker}}", -- re-enable, so it does not disturb stuff from interactive shell
		},
	},
	clearLog = {
		javascript = "console.clear(); // {{marker}}",
		python = "clear()  # {{marker}}",
		sh = "clear # {{marker}}",
	},
	timeLogStart = { -- special = index
		lua = "local timelogStart{{index}} = os.clock() -- {{marker}}",
		python = "local timelog_start_{{index}} = time.perf_counter()  # {{marker}}",
		javascript = "const timelogStart{{index}} = Date.now(); // {{marker}}", -- not all JS engines support console.time
		typescript = 'console.time("#{{index}} {{marker}}");', -- string needs to be identical to `console.timeEnd`
		sh = "timelog_start_{{index}}=$(date +%%s) # {{marker}}",
		ruby = "timelog_start_{{index}} = Process.clock_gettime(Process::CLOCK_MONOTONIC) # {{marker}}",
	},
	timeLogStop = { -- index = index
		lua = 'print(("#{{index}} {{marker}}: %%.3fs"):format(os.clock() - timelogStart{{index}}))',
		nvim_lua = 'vim.notify(("#{{index}} {{marker}}: %%.3fs"):format(os.clock() - timelogStart{{index}}))',
		python = 'print(f"#{{index}} {{marker}}: {round(time.perf_counter() - timelog_start_{{index}}, 3)}s")',
		javascript = "console.log(`#{{index}} {{marker}}: ${(Date.now() - timelogStart{{index}}) / 1000}s`);",
		typescript = 'console.timeEnd("#%s %s");',
		sh = 'echo "#{{index}} %s $(($(date +%{{marker}}) - timelog_start_{{index}}))s" >&2',
		ruby = 'puts "#{{index}} {{marker}}: #{Process.clock_gettime(Process::CLOCK_MONOTONIC) - timelog_start_{{index}}}s"',
	},
}

--------------------------------------------------------------------------------
return M
