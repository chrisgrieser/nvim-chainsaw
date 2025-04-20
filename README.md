<!-- LTeX: enabled=false -->
# nvim-chainsaw 🪚
<!-- LTeX: enabled=true -->
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-chainsaw">
<img alt="badge" src="https://dotfyle.com/plugins/chrisgrieser/nvim-chainsaw/shield"/></a>

Quick and feature-rich insertion of various kinds of log statements.

<https://github.com/chrisgrieser/nvim-chainsaw/assets/73286100/fa55ae24-deba-4fed-84e9-554d9a695ad9>

## Table of Contents

<!-- toc -->

- [Features](#features)
- [Installation](#installation)
- [Built-in language support](#built-in-language-support)
- [Usage](#usage)
	* [List of commands](#list-of-commands)
	* [Smart variable detection](#smart-variable-detection)
	* [Smart insertion location](#smart-insertion-location)
- [Configuration](#configuration)
	* [Basic configuration](#basic-configuration)
	* [Customize log statements](#customize-log-statements)
	* [The global pretty-logging function `Chainsaw()`](#the-global-pretty-logging-function-chainsaw)
	* [Make the formatter ignore the log statements](#make-the-formatter-ignore-the-log-statements)
	* [Status line](#status-line)
- [Comparison with similar plugins](#comparison-with-similar-plugins)
- [About the developer](#about-the-developer)

<!-- tocstop -->

## Features
- Quick insertion of log statements for the variable under the cursor
  (normal mode) or the selection (visual mode).
- [Smart detection of the variable under the cursor](#smart-variable-detection)
  and the [correct insertion location of the log
  statement](#smart-insertion-location) via Treesitter.
- Commands for a dozen different log statement types, including assert
  statements, stack traces, or acoustic logging. All commands are
  dot-repeatable.
- Built-in support for ~20 common languages, with dedicated support for
  `nvim-lua`. Easy configuration for additional languages.
- Helper commands to remove all log statements created by `nvim-chainsaw` or to
  clear the console.
- Flexible templating options for customizing log statements, including support
  for multi-line templates.
- Status line component to display the count of log statements in the current
  buffer. Visual indication of log statements via line-highlights, signcolumn,
  or scrollbar (when using
  [satellite.nvim](https://github.com/lewis6991/satellite.nvim)).
- Auto-install a pre-commit hook that prevents committing files with the log
  statements created by `nvim-chainsaw` (opt-in).

## Installation
**Requirements**
- nvim 0.10+
- Treesitter parser for the languages you with this plugin

```lua
-- lazy.nvim
{ 
	"chrisgrieser/nvim-chainsaw", 
	event = "VeryLazy",
	opts = {} -- required even if left empty
},

-- packer
use { 
	"chrisgrieser/nvim-chainsaw"
	config = function () 
		require("chainsaw").setup()
	end,
}
```

Note that the `.setup()` call (or `lazy.nvim`'s `opts`) is required, even if
called without options.

## Built-in language support
- JavaScript/TypeScript (and supersets)
- Python
- Lua (with special considerations for `nvim-lua`[^1])
- bash & zsh
- AppleScript
- Ruby
- Rust
- CSS[^2] (and supersets)
- Go[^3]
- Swift

Not every language supports every type of log statement. For the concrete
statements used, see
[log-statements-data.lua](./lua/chainsaw/config/log-statements-data.lua).

[^1]: `nvim_lua` uses log statements that inspect objects and is designed to
	work with various notification plugins like `nvim-notify`, `snacks.nvim`, or
	`noice.nvim`.
[^2]: Uses statements such as `outline: 2px solid red !important;` that are the
	 somewhat similar logging.
[^3]: The packages `fmt` and `time` need to be imported manually.

## Usage

### List of commands
The plugin offers various types of log statements. Bind keymaps for the ones you
want to use.

All operations are dot-repeatable.

```lua
-- log the name & value of the variable under the cursor
require("chainsaw").variableLog()

-- like variableLog, but with syntax specific to inspect an object, for example
-- `console.log(JSON.stringify(foobar))` in javascript
require("chainsaw").objectLog()

-- inspect the type of the variable under cursor, such as `typeof foo` in js
require("chainsaw").typeLog()

-- assertion statement for variable under cursor
require("chainsaw").assertLog()

-- Minimal log statement, with an emoji for differentiation. Intended for
-- control flow inspection, that is to quickly glance whether a condition was
-- triggered or not.
require("chainsaw").emojiLog()

-- Sound-playing statement for audible debugging.
-- Depending on the type of log statement, it is either a terminal bell
-- (requiring the terminal) or a system sound.
-- Inspired by https://news.ycombinator.com/item?id=41519046
require("chainsaw").sound()

-- create log statement, and position the cursor to enter a message
require("chainsaw").messageLog()

-- 1st call: start measuring the time
-- 2nd call: log the time duration since the 1st statement
require("chainsaw").timeLog()

-- debug statements like `debugger` in javascript or `breakpoint()` in python
require("chainsaw").debugLog()

-- prints the stacktrace of the current call
require("chainsaw").stacktraceLog()

-- clearing statement, such as `console.clear()`
require("chainsaw").clearLog()

---------------------------------------------------

-- remove all log statements or all log statements in visually selected region 
-- created by nvim-chainsaw 
require("chainsaw").removeLogs()
```

These features can also be accessed with the user command `:Chainsaw`. Each
option corresponds to the commands above. For example, `:Chainsaw
variableLog` is same as `:lua require("chainsaw").variableLog()`.

When using lua functions, `variableLog`, `objectLog`, `typeLog`, and `assertLog`
can also be used in **visual mode** to use the visual selection instead of the
word under the cursor. `removeLogs` can also be used in visual mode to only
remove log statements inside the selected lines.

### Smart variable detection
When the variable under the cursor is an object with fields, `chainsaw` attempts
to automatically select the correct field. (Note that this feature requires the
Treesitter parser of the respective language.)

```lua
myVariable.myF[i]eld = "foobar"
-- prints: myVariable.myField

myVa[r]iable.myField = "foobar"
-- prints: myVariable
```

Filetypes currently supporting this feature:
- Lua (and `nvim_lua`)
- Python
- JavaScript (and supersets)

PRs adding support for more languages are welcome. See
[smart-var-detect.lua](./lua/chainsaw/config/smart-var-detect.lua).

### Smart insertion location
`chainsaw` by default inserts the log statement below the cursor. The insertion
location is automatically adapted if doing would result in invalid code. (Note
that this feature requires the Treesitter parser of the respective language.)

```lua
-- [] marks the cursor position

-- default case: will insert the log statement below the cursor
local f[o]obar = 1

-- multi-line assignments: will insert log statement below the `}` line
local f[o]o = {
	bar = 1
}

-- returns: will insert log statement above the `return` line
local function foobar()
	return f[o]o
end
```

Filetypes currently supporting this feature:
- Lua (and `nvim_lua`)
- JavaScript (and supersets)

PRs adding support for more languages are welcome. See
[smart-insert-location.lua](./lua/chainsaw/config/smart-insert-location.lua).

## Configuration
The `setup()` call is required.

### Basic configuration

```lua
-- default settings
require("chainsaw").setup {
	-- The marker should be a unique string, since signs and highlgiths are based
	-- on it and since `.removeLogs()` will remove any line with it. Thus, emojis
	-- or unique strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- Appearance of lines with the marker
	visuals = {
		icon = "󰹈", -- as opposed to the marker only used in nvim, thus nerdfont glyphs are okay
		signHlgroup = "DiagnosticSignInfo",
		signPriority = 50,
		lineHlgroup = false,

		nvimSatelliteIntegration = {
			enabled = true,
			hlgroup = "DiagnosticSignInfo",
			icon = "▪",
			leftOfScrollbar = false,
			priority = 40, -- compared to other handlers (diagnostics are 50)
		},
	},

	-- Auto-install a pre-commit hook that prevents commits containing the marker
	-- string. Will not be installed if there is already another pre-commit-hook.
	preCommitHook = {
		enabled = false,
		notifyOnInstall = true,
		hookPath = ".chainsaw", -- relative to git root

		-- Will insert the marker as `%s`. (Pre-commit hooks requires a shebang
		-- and exit non-zero when marker is found to block the commit.)
		hookContent = [[#!/bin/sh
			if git grep --fixed-strings --line-number "%s" .; then
				echo
				echo "nvim-chainsaw marker found. Aborting commit."
				exit 1
			fi
		]],

		-- Relevant if you track your nvim-config via git and use a custom marker,
		-- as your config will then always include the marker ans falsely trigger
		-- the pre-commit hook.
		notInNvimConfigDir = true,

		-- List of git roots where the hook should not be installed. Supports
		-- globs and `~`. Must match the full directory.
		dontInstallInDirs = {
			-- "~/special-project"
			-- "~/repos/**",
		},
	},

	-- configuration for specific logtypes
	logTypes = {
		emojiLog = {
			emojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },
		},
	},

	-----------------------------------------------------------------------------
	-- see https://github.com/chrisgrieser/nvim-chainsaw/blob/main/lua/chainsaw/config/log-statements-data.lua
	logStatements = require("chainsaw.config.log-statements-data").logStatements,
	supersets = require("chainsaw.config.log-statements-data").supersets,
}
```

### Customize log statements
New log statements can be added, and existing log statements can be modified
under the config `logStatements`. See
[log-statements-data.lua](./lua/chainsaw/config/log-statements-data.lua) for
the built-in log statements as reference. PRs adding log statements for more
languages are welcome.

There are various **placeholders** that are dynamically replaced:
- `{{marker}}` inserts the value from `config.marker`. Each log statement should
  have one, so that the line can be removed via `.removeLogs()`.
- `{{var}}`: variable as described further above.
- `{{time}}`: timestamp formatted as `HH:MM:SS` (for millisecond-precision, use
  `.timeLog()` instead)
- `{{filename}}`: basename of the current file
- `{{lnum}}`: current line number
- `.emojiLog()` only: `{{emoji}}` inserts the emoji
- `.timeLog()` only: `{{index}}` inserts a running index. (Needed to
  differentiate between variables when using `timeLog` multiple times).

```lua
require("chainsaw").setup ({
	logStatements = {
		variableLog = {
			javascript = 'console.log("{{marker}} {{var}}:", {{var}});',
			otherFiletype = … -- <-- add the statement for your filetype here
		},
		-- the same way for the other log statement operations
	},
})
```

> [!NOTE]
> The strings may not include line breaks. If you want to use multi-line log
> statements, use a list of strings instead, each string representing one line.

### The global pretty-logging function `Chainsaw()`
<img alt="Showcase nvim-lua-debug function" width=75% src="https://github.com/user-attachments/assets/39681485-f077-421f-865d-c65a7c35a3c3">

The plugin provides a globally accessible function `Chainsaw()`, specifically
designed for debugging `nvim_lua`. Given a variable, it pretty-prints the
variable, its name, and the location of the log statement call, all in a much
more concise manner.

**Requirements:** A notification plugin like
[nvim-notify](https://github.com/rcarriga/nvim-notify) or
[snacks.nvim](http://github.com/folke/snacks.nvim). Syntax highlighting inside
the notification requires `snacks.nvim`.

**Setup:** You can use it by setting a custom log statement like this:

```lua
require("chainsaw").setup {
	logStatements = {
		variableLog = {
			nvim_lua = "Chainsaw({{var}}) -- {{marker}}",
		},
	},
}
```

> [!TIP]
> To use `Chainsaw()` during or shortly after startup, you may not lazy-load
> `nvim-chainsaw`. Using `lazy.nvim`, set `lazy = false` and if needed `priority
> = 200` to ensure the plugin loads before other start-plugins.

The `lua_ls` diagnostic `undefined-global` for `Chainsaw` can be disabled with
one of the following methods:

<details>
<summary>Options</summary>

```lua
-- Option 1: nvim-lspconfig
require("lspconfig").lua_ls.setup {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "Chainsaw", "vim" },
			},
		},
	},
}
```

```jsonc
// Option 2: .luarc.json
{
	"diagnostics": {
		"globals": ["Chainsaw", "vim"],
	},
}
```

```lua
-- Option 3: lazydev.nvim
opts = {
	library = {
		{ path = "nvim-chainsaw", words = { "Chainsaw" } },
	},
},
```

</details>

### Make the formatter ignore the log statements
A common problem is that formatters like `prettier` split up the log statements
into multiple lines, making them hard to read and breaking `.removeLogs()`, which
relies on each line containing the marker emoji.

The simplest method to deal with this is to customize the log statement in your
configuration to include an ignore-comment: `/* prettier-ignore */`
- The log statements do not accept lines, but you can use a list of strings,
  where each element is one line.
- Add the marker to the added line as well, so it is included in the removal by
  `.removeLogs()`.

```lua
require("chainsaw").setup {
	logStatements = {
		variableLog = {
			javascript = {
				"/* prettier-ignore */ // {{marker}}",
				'console.log("{{marker}} {{var}}:", {{var}});',
			},
		},
	},
}
```

### Status line
This function returns number of log statements by `nvim-chainsaw` in the current
buffer, for use in your status line.

```lua
require("chainsaw.visuals.statusline").countInBuffer()
```

## Comparison with similar plugins

<!-- LTeX: enabled=false -->
|                                                   | nvim-chainsaw                                                                                          | debugprint.nvim                                                           | timber.nvim                                                     |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- | --------------------------------------------------------------- |
| log types                                         | variables, objects, asserts, types, sound, stacktraces, emoji, messages, debugger, time, clear-console | variables                                                                 | variables, objects, time                                        |
| builtin language support                          | ~20                                                                                                    | ~35                                                                       | ~15                                                             |
| inheritance of log statements from superset langs | ✅                                                                                                      | ✅                                                                         | ❌                                                               |
| delete all log statements                         | ✅                                                                                                      | ✅                                                                         | ✅                                                               |
| comment all log statements                        | ❌                                                                                                      | ✅                                                                         | ✅                                                               |
| protection to accidentally commit log statements  | via auto-installed pre-commit hook (opt-in)                                                            | ❌                                                                         | ❌                                                               |
| log statement customization                       | line numbers, filenames, time, multi-line statements                                                   | line numbers+filename (location), nearby line snippet, unique counter     | line numbers, insertation location                              |
| insertation location                              | below, treesitter-based adjustments for some languages                                                 | below, above                                                              | below, above, surround, operator, treesitter-based adjustments  |
| variable detection                                | word under cursor, visual selection, treesitter-based selection                                        | word under cursor, operator, visual selection, treesitter-based selection | word under cursor, visual selection, treesitter-based selection |
| dot-repeatability                                 | ✅                                                                                                      | ✅                                                                         | ✅                                                               |
| visual emphasis of log statements                 | signcolumn, line-highlight, status line, scrollbar                                                      | ❌                                                                         | flash on inserting statement                                    |
| extra features for `nvim_lua`                     | separate configuration, availability of global debugging function                                      | ❌                                                                         | ❌                                                               |
| log file watcher                                  | ❌                                                                                                      | ❌                                                                         | ✅                                                               |
| maintainability / efficiency                      | ~1000 LoC                                                                                              | ~1600 LoC                                                                 | ~4500 LoC (excluding tests)                                     |
<!-- LTeX: enabled=true -->

## About the developer
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

- [Website](https://chris-grieser.de/)
- [Mastodon](https://pkm.social/@pseudometa)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'><img height='36'
style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
