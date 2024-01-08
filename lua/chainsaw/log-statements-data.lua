---@alias logStatementData table<string, table<string, string|string[]>>

---@type logStatementData
return {
	variableLog = {
		lua = 'print("%s %s: ", %s)',
		nvim_lua = 'vim.notify("%s %s: " .. tostring(%s))', -- not using `print` due to noice.nvim https://github.com/folke/noice.nvim/issues/556
		python = 'print(f"%s {%s = }")',
		javascript = 'console.log("%s %s:", %s);',
		typescript = 'console.log("%s %s:", %s);',
		typescriptreact = 'console.log("%s %s:", %s);',
		sh = 'echo "%s %s: $%s"',
		applescript = 'log "%s %s:" & %s',
		css = "outline: 2px solid red !important; /* %s */",
		scss = "outline: 2px solid red !important; /* %s */",
		rust = 'println!("{} {}: {:?}", "%s", "%s", %s);'
	},
	objectLog = {
		nvim_lua = 'vim.notify("%s %s: " .. vim.inspect(%s))',
		typescript = 'console.log("%s %s:", %s)',
		typescriptreact = 'console.log("%s %s:", %s)',
		javascript = 'console.log("%s %s:", JSON.stringify(%s))',
	},
	beepLog = {
		nvim_lua = 'vim.notify("%s beep %s")',
		lua = 'print("%s beep %s")',
		python = 'print("%s beep %s")',
		javascript = 'console.log("%s beep %s");',
		typescript = 'console.log("%s beep %s");',
		typescriptreact = 'console.log("%s beep %s");',
		sh = 'echo "%s beep %s"',
		applescript = "beep -- %s",
		css = "outline: 2px solid red !important; /* %s */",
		scss = "outline: 2px solid red !important; /* %s */",
	},
	messageLog = {
		lua = 'print("%s ")',
		nvim_lua = 'vim.notify("%s ")', -- not using `print` due to noice.nvim https://github.com/folke/noice.nvim/issues/556
		python = 'print("%s ")',
		javascript = 'console.log("%s ");',
		typescript = 'console.log("%s ");',
		typescriptreact = 'console.log("%s ");',
		sh = 'echo "%s "',
		applescript = 'log "%s "',
		rust = 'println!("{} ", "%s");'
	},
	assertLog = {
		lua = 'assert(%s, "%s %s")',
		nvim_lua = 'assert(%s, "%s %s")',
		python = 'assert %s, "%s %s"',
	},
	debugLog = {
		javascript = "debugger; // %s",
		typescript = "debugger; // %s",
		typescriptreact = "debugger; // %s",
		python = "breakpoint()  # %s", -- https://docs.python.org/3.11/library/functions.html?highlight=breakpoint#breakpoint
		sh = { -- https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
			"set -exuo pipefail # %s",
			"set +exuo pipefail # %s", -- re-enable, so it does not disturb stuff from interactive shell
		},
	},
	timeLogStart = {
		nvim_lua = "local timelogStart = os.time() -- %s",
		lua = "local timelogStart = os.time() -- %s",
		python = "local timelogStart = time.perf_counter()  # %s",
		javascript = "const timelogStart = +new Date(); // %s", -- not all JS engines support console.time()
		typescript = 'console.time("%s");',
		typescriptreact = 'console.time("%s");',
		sh = "timelogStart=$(date +%%s) # %s",
	},
	timeLogStop = {
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
			'echo "%s ${durationSecs}s"',
		},
	},
}
