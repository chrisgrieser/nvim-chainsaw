--------------------------------------------------------------------------------
-- INFO 1. The strings may not include linebreaks. If you want to use multi-line log
-- statements, use a list of strings instead, each string representing one line.
-- 2. Use `{{placerholder}}` to insert vars, marker, etc.
-- 3. See `superset-inheritance.lua` for superset-languages.
-- (e.g, `typescript` inheriting log statements from `javascript`.)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local M = {}

---@alias logStatementData table<string, table<string, string|string[]?>>

---@type logStatementData
M.logStatements = {
	variableLog = {
		applescript = 'log "{{marker}} {{var}}:" & {{var}}',
		css = "outline: 2px solid red !important; /* {{marker}} */",
		go = 'fmt.Println("{{marker}} {{var}}:", {{var}})',
		javascript = 'console.log("{{marker}} {{var}}:", {{var}});',
		lua = 'print("{{marker}} {{var}}: " .. tostring({{var}}))',
		nvim_lua = 'vim.notify(vim.inspect({{var}}), nil, { title = "{{marker}} {{var}}", ft = "lua" })',
		python = 'print(f"{{marker}} { {{var}} = }")',
		ruby = 'puts "{{marker}} {{var}}: #{{{var}}}"',
		rust = 'println!("{} {}: {:?}", "{{marker}}", "{{var}}", {{var}});',
		sh = 'echo "{{marker}} {{var}}: ${{var}}" >&2', -- `>&2` sends to stderr only
		swift = 'print("{{marker}} {{var}}:", {{var}})',
	},
	objectLog = {
		go = 'fmt.Println("{{marker}} {{var}}:", {{var}})',
		javascript = 'console.log("{{marker}} {{var}}:", JSON.stringify({{var}}, null, 2))', -- `2` ensures it's pretty-printed
		ruby = 'puts "{{marker}} {{var}}: #{{{var}}.inspect}"',
		rust = 'println!("{} {}: {:?}", "{{marker}}", "{{var}}", {{var}});',
		swift = "dump({{var}}, maxItems: 10)  // {{marker}}",
	},
	assertLog = {
		javascript = 'if (!{{var}}) throw new Error("{{marker}} {{var}} {{insert}}");', -- no native assert in JS
		lua = 'assert({{var}}, "{{marker}} {{var}} {{insert}}")',
		python = 'assert {{var}}, "{{marker}} {{var}} {{insert}}"',
		rust = 'assert!({{var}}, "{} {}", "{{marker}}", "{{var}} {{insert}}");',
		swift = 'assert({{var}} != nil, "{{marker}} {{var}} {{insert}}")',
		typescript = 'console.assert({{var}}, "{{marker}} {{var}} {{insert}}");',
	},
	typeLog = {
		go = 'fmt.Println("{{marker}} {{var}}: type is", fmt.Sprintf("%T", {{var}}))',
		javascript = 'console.log("{{marker}} {{var}}: type is " + typeof {{var}})',
		lua = 'print("{{marker}} {{var}}: type is " .. type({{var}}))',
		nvim_lua = 'vim.notify("{{marker}} {{var}}: type is " .. type({{var}}))',
		python = 'print(f"{{marker}} {{var}}: type is {type({{var}})}")',
		swift = 'print("{{marker}} {{var}}: type is \\(type(of: {{var}}))")',
	},
	emojiLog = {
		applescript = 'log "{{marker}} {{emoji}}"',
		go = 'fmt.Println("{{marker}} {{emoji}}")',
		javascript = 'console.log("{{marker}} {{emoji}}");',
		lua = 'print("{{marker}} {{emoji}}")',
		nvim_lua = 'vim.notify("{{marker}} {{emoji}}")',
		python = 'print("{{marker}} {{emoji}}")',
		ruby = 'puts "{{marker}} {{emoji}}"',
		rust = 'println!("{} {}", "{{marker}}", "{{emoji}}");',
		sh = 'echo "{{marker}} {{emoji}}" >&2',
		swift = 'print("{{marker}} {{emoji}}")',
	},
	sound = { -- NOTE `\a` is terminal bell, the other commands are system sound
		applescript = "beep -- {{marker}}",
		go = 'fmt.Println("\\a") // {{marker}}',
		javascript = 'new Audio("data:audio/wav;base64,UklGRl9vT19XQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YU"+Array(800).join("200")).play(); // {{marker}}',
		-- macOS only, since relying on `osascript`
		lua = jit.os == "OSX" and [[os.execute("osascript -e 'beep'") -- {{marker}}]] or nil,
		nvim_lua = jit.os == "OSX" and 'vim.system({"osascript", "-e", "beep"}) -- {{marker}}' or nil,
		python = 'print("\\a")  # {{marker}}',
		sh = 'printf "\\a" # {{marker}}',
		swift = 'print("\\u{07}")',
	},
	messageLog = {
		applescript = 'log "{{marker}} {{insert}}"',
		go = 'fmt.Println("{{marker}} ")',
		javascript = 'console.log("{{marker}} {{insert}}");',
		lua = 'print("{{marker}} {{insert}}")',
		nvim_lua = 'vim.notify("{{marker}} {{insert}}")',
		python = 'print("{{marker}} {{insert}}")',
		ruby = 'puts "{{marker}} {{insert}}"',
		rust = 'println!("{} ", "{{marker}} {{insert}}");',
		sh = 'echo "{{marker}} {{insert}}" >&2',
		swift = 'print("{{marker}} {{insert}}")',
	},
	stacktraceLog = {
		bash = "print '{{marker}} stacktrace: ' ; caller 0",
		javascript = 'console.log("{{marker}} stacktrace: ", new Error()?.stack?.replaceAll("\\n", " "));', -- not all JS engines support console.trace()
		lua = 'print(debug.traceback("{{marker}}"))', -- `debug.traceback` already prepends "stacktrace"
		nvim_lua = 'vim.notify(debug.traceback("{{marker}}"))',
		typescript = 'console.trace("{{marker}} stacktrace: ");',
		zsh = 'print "{{marker}} stacktrack: $funcfiletrace $funcstack"',
	},
	debugLog = {
		javascript = "debugger; // {{marker}}",
		python = "breakpoint()  # {{marker}}",
		rust = "dbg!(&{{var}}); // {{marker}}",
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
	timeLogStart = {
		go = "var timelog_start_{{index}} = time.Now() // {{marker}}",
		javascript = "const timelogStart{{index}} = Date.now(); // {{marker}}", -- not all JS engines support console.time
		lua = "local timelogStart{{index}} = os.clock() -- {{marker}}",
		python = "timelog_start_{{index}} = time.perf_counter()  # {{marker}}",
		ruby = "timelog_start_{{index}} = Process.clock_gettime(Process::CLOCK_MONOTONIC) # {{marker}}",
		rust = "let timelog_start_{{index}} = std::time::Instant::now(); // {{marker}}",
		sh = "timelog_start_{{index}}=$(date +%s) # {{marker}}",
		swift = "let timelogStart{{index}} = Date() //  {{marker}}",
		typescript = 'console.time("#{{index}} {{marker}}");', -- string needs to be identical to `console.timeEnd`
	},
	timeLogStop = {
		go = 'fmt.Println("#{{index}} {{marker}}:", time.Since(timelog_start_{{index}})) // {{marker}}',
		javascript = "console.log(`#{{index}} {{marker}}: ${(Date.now() - timelogStart{{index}}) / 1000}s`);",
		lua = 'print(("#{{index}} {{marker}}: %%.3fs"):format(os.clock() - timelogStart{{index}}))',
		nvim_lua = 'vim.notify(("#{{index}} {{marker}}: %%.3fs"):format(os.clock() - timelogStart{{index}}))',
		python = 'print(f"#{{index}} {{marker}}: {round(time.perf_counter() - timelog_start_{{index}}, 3)}s")',
		ruby = 'puts "#{{index}} {{marker}}: #{Process.clock_gettime(Process::CLOCK_MONOTONIC) - timelog_start_{{index}}}s"',
		rust = 'println!("{} #{}: {}", "{{marker}}", "{{index}}", timelog_start_{{index}}.elapsed().as_millis());',
		sh = 'echo "#{{index}} {{marker}} $(($(date +%s) - timelog_start_{{index}}))s" >&2',
		swift = 'print("#{{index}} {{marker}}: \\(Date().timeIntervalSince(timelogStart{{index}}))")',
		typescript = 'console.timeEnd("#{{index}} {{marker}}");', -- string needs to be identical to `console.timeEnd`
	},
}

-- If a filetype has no configuration for a specific logtype, look in this table
-- for a related filetype, and use its log statements
---@type table<string, string>
M.supersets = {
	bash = "sh",
	fish = "sh",
	javascriptreact = "javascript",
	less = "css",
	nvim_lua = "lua", -- `nvim_lua` config is used when in nvim-lua
	sass = "css",
	scss = "css",
	svelte = "typescript",
	typescript = "javascript",
	typescriptreact = "typescript",
	vue = "typescript",
	zsh = "sh",
}

--------------------------------------------------------------------------------
return M
