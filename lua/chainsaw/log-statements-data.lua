---@alias logStatementData table<string, table<string, string|string[]>>

--------------------------------------------------------------------------------
-- INFO
-- the strings may not include linebreaks. If you want to use multi-line log
-- statements, use a list of strings instead, each string representing one line.
--------------------------------------------------------------------------------

---@type logStatementData
return {
	variableLog = { -- %s -> 1st: marker, 2nd: variable, 3rd: variable
		lua = 'print("%s %s: ", %s)',
		nvim_lua = 'vim.notify("%s %s: " .. tostring(%s))', -- not using `print` due to noice.nvim https://github.com/folke/noice.nvim/issues/556
		python = 'print(f"%s {%s = }")',
		javascript = 'console.log("%s %s:", %s);',
		typescript = 'console.log("%s %s:", %s);',
		typescriptreact = 'console.log("%s %s:", %s);',
		sh = 'echo "%s %s: $%s" >&2',
		applescript = 'log "%s %s:" & %s',
		css = "outline: 2px solid red !important; /* %s */",
		scss = "outline: 2px solid red !important; /* %s */",
		rust = 'println!("{} {}: {:?}", "%s", "%s", %s);',
		ruby = 'puts "%s %s: #{%s}"',
	},
	objectLog = { -- %s -> 1st: marker, 2nd: variable, 3rd: variable
		nvim_lua = 'vim.notify("%s %s: " .. vim.inspect(%s))',
		typescript = 'console.log("%s %s:", JSON.stringify(%s))',
		typescriptreact = 'console.log("%s %s:", JSON.stringify(%s))',
		javascript = 'console.log("%s %s:", JSON.stringify(%s))',
		ruby = 'puts "%s %s: #{%s.inspect}"',
	},
	stacktraceLog = { -- %s -> marker
		lua = 'print(debug.traceback("%s"))', -- `debug.traceback` already prepends "stacktrace"
		nvim_lua = 'vim.notify(debug.traceback("%s"))',
		sh = 'print "%s stacktrack: $funcfiletrace $funcstack"', -- defaulting to zsh here, since it's more common than bash
		zsh = 'print "%s stacktrack: $funcfiletrace $funcstack"',
		bash = "print '%s stacktrace: ' ; caller 0",
		javascript = 'console.log("%s stacktrace: ", new Error().stack.replaceAll("\n", " "));', -- not all JS engines support console.trace()
		typescript = 'console.trace("%s stacktrace: ");',
		typescriptreact = 'console.trace("%s stacktrace: ");',
	},
	beepLog = { -- %s -> 1st: marker, 2nd: beepEmoji
		nvim_lua = 'vim.notify("%s beep %s")',
		lua = 'print("%s beep %s")',
		python = 'print("%s beep %s")',
		javascript = 'console.log("%s beep %s");',
		typescript = 'console.log("%s beep %s");',
		typescriptreact = 'console.log("%s beep %s");',
		sh = 'echo "%s beep %s" >&2',
		applescript = "beep -- %s",
		css = "outline: 2px solid red !important; /* %s */",
		scss = "outline: 2px solid red !important; /* %s */",
		ruby = 'puts "%s beep %s"',
	},
	messageLog = { -- %s -> marker
		lua = 'print("%s ")',
		nvim_lua = 'vim.notify("%s ")', -- not using `print` due to noice.nvim https://github.com/folke/noice.nvim/issues/556
		python = 'print("%s ")',
		javascript = 'console.log("%s ");',
		typescript = 'console.log("%s ");',
		typescriptreact = 'console.log("%s ");',
		sh = 'echo "%s " >&2',
		applescript = 'log "%s "',
		rust = 'println!("{} ", "%s");',
		ruby = 'puts "%s "',
	},
	assertLog = { -- %s -> 1st: variable, 2nd: marker, 3rd: variable
		lua = 'assert(%s, "%s %s")',
		nvim_lua = 'assert(%s, "%s %s")',
		python = 'assert %s, "%s %s"',
	},
	debugLog = { -- %s -> marker
		javascript = "debugger; // %s",
		typescript = "debugger; // %s",
		typescriptreact = "debugger; // %s",
		python = "breakpoint()  # %s", -- https://docs.python.org/3.11/library/functions.html?highlight=breakpoint#breakpoint
		sh = {
			"set -exuo pipefail # %s", -- https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
			"set +exuo pipefail # %s", -- re-enable, so it does not disturb stuff from interactive shell
		},
	},
	timeLogStart = { -- %s -> marker
		nvim_lua = "local timelogStart = os.time() -- %s",
		lua = "local timelogStart = os.time() -- %s",
		python = "local timelogStart = time.perf_counter()  # %s",
		javascript = "const timelogStart = +new Date(); // %s", -- not all JS engines support console.time()
		typescript = 'console.time("%s");',
		typescriptreact = 'console.time("%s");',
		sh = "timelogStart=$(date +%%s) # %s",
		ruby = "timelog_start = Process.clock_gettime(Process::CLOCK_MONOTONIC) # %s",
	},
	timeLogStop = { -- %s -> marker
		nvim_lua = {
			"local durationSecs = os.difftime(os.time(), timelogStart) -- %s",
			'print("%s:", durationSecs, "s")',
		},
		lua = {
			"local durationSecs = os.difftime(os.time(), timelogStart) -- %s",
			'print("%s:", durationSecs, "s")',
		},
		python = {
			"durationSecs = round(time.perf_counter() - timelogStart, 3)  # %s",
			'print(f"%s: {durationSecs}s")',
		},
		javascript = {
			"const durationSecs = (+new Date() - timelogStart) / 1000; // %s",
			"console.log(`%s: ${durationSecs}s`);",
		},
		typescript = 'console.timeEnd("%s");',
		typescriptreact = 'console.timeEnd("%s");',
		sh = {
			"timelogEnd=$(date +%%s) && durationSecs = $((timelogEnd - timelogStart)) # %s",
			'echo "%s ${durationSecs}s" >&2',
		},
		ruby = {
			"duration_secs = Process.clock_gettime(Process::CLOCK_MONOTONIC) - timelog_start # %s",
			'puts "%s: #{duration_secs}s"',
		},
	},
}
