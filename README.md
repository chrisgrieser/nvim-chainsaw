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
	* [Smart insertion locations](#smart-insertion-locations)
- [Configuration](#configuration)
	* [Base configuration](#base-configuration)
	* [Customize log statements](#customize-log-statements)
	* [Have your formatter ignore the log statements](#have-your-formatter-ignore-the-log-statements)
	* [Statusline](#statusline)
- [Similar plugins](#similar-plugins)
- [About the developer](#about-the-developer)

<!-- tocstop -->

## Features
- Quick insertion of log statements for the variable under the cursor
  (normal mode) or the selection (visual mode).
- [Smart detection of the variable under the cursor](#smart-variable-detection)
  and the [correct insertion location of the log
  statement](#smart-insertion-location) via Treesitter.
- Commands for a dozen different log statement types, including assert
  statements, stacktraces, or acoustic logging. All commands are dot-repeatable.
- Builtin support for ~20 common languages, with dedicated support for
  `nvim-lua`, and easy configuration for additional languages.
- Helper commands to remove all log statements created by `nvim-chainsaw` or to
  clear the console.
- Flexible templating options for customizing log statements, including support
  for multi-line templates.
- Visual indication of log statements via highlights, signcolumn, or scrollbar
  (when using [satellite.nvim](https://github.com/lewis6991/satellite.nvim)).

## Installation
**Requirements**
- nvim 0.10 or higher.
- Recommended: Treesitter parser for the respective languages to enable [smart
  variable identification](#smart-variable-identification) and [smart insertion
  locations](#smart-insertion-locations).

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

*The plugin needs to be loaded for highlights, signs, and scrollbar items to be
displayed. If you do not care about them, you can also remove the early loading
via `event = "VeryLazy"`.*

## Built-in language support
- JavaScript/TypeScript (and supersets)
- Python
- Lua (with special considerations for `nvim-lua`[^1])
- Shell (and supersets)
- AppleScript
- Ruby
- Rust
- CSS[^2] (and supersets)
- Go[^3]

Not every language supports every type of log statement. For the concrete
statements used, see
[log-statements-data.lua](./lua/chainsaw/config/log-statements-data.lua).

[^1]: `variableLog` for `nvim_lua` uses a log statement that inspects objects
	and is designed to work with various notification plugins like
	`nvim-notify`, `snacks.nvim`, or `noice.nvim`. If using `snacks.nvim`, lua
	syntax highlighting is added as well.
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

-- like variableLog, but with syntax specific to inspect an object such as
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
-- 2nd call: logs the time duration since
require("chainsaw").timeLog()

-- debug statements like `debugger` in javascript or `breakpoint()` in python
require("chainsaw").debugLog()

-- prints the stacktrace of the current call
require("chainsaw").stacktraceLog()

-- clearing statement, such as `console.clear()`
require("chainsaw").clearLog()

---------------------------------------------------

-- remove all log statements created by nvim-chainsaw
require("chainsaw").removeLogs()
```

These features can also be accessed with the user command `:Chainsaw`. Each
option corresponds to the commands above. For example, `:Chainsaw
variableLog` is same as `:lua require("chainsaw").variableLog()`.

When using lua functions, `variableLog`, `objectLog`, `typeLog`, and `assertLog`
can also be used in **visual mode** to use the visual selection instead of the
word under the cursor.

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

### Smart insertion locations
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

### Base configuration

```lua
-- default settings
require("chainsaw").setup {
	-- The marker should be a unique string, since signs and highlgiths are based
	-- on it and since `.removeLogs()` will remove any line with it. Thus, emojis
	-- or unique strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- Appearance of lines with the marker
	visuals = {
		sign = "󰹈",
		signHlgroup = "DiagnosticSignInfo",
		statuslineIcon = "󰹈",
		lineHlgroup = false,

		nvimSatelliteIntegration = {
			enabled = true,
			hlgroup = "DiagnosticSignInfo",
			icon = "▪",
			leftOfScrollbar = false,
			priority = 40, -- compared to other handlers (diagnostics are 50)
		},
	},

	-- configuration for specific logtypes
	logtypes = {
		emojiLog = {
			emojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },
		},
	},

	-- If a filetype has no configuration for a specific logtype, then it will
	-- look for the configuration for a superset of that filetype.
	supersets = {
		nvim_lua = "lua", -- `nvim_lua` config is used when in nvim-lua
		typescript = "javascript",
		typescriptreact = "typescript",
		javascriptreact = "javascript",
		vue = "typescript",
		svelte = "typescript",
		bash = "sh",
		zsh = "sh",
		fish = "sh",
		scss = "css",
		less = "css",
		sass = "css",
	},

	logStatements = require("chainsaw.config.log-statements-data"),
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
- `{{file}}`: basename of the current file
- `{{lnum}}`: current line number
- *`.emojiLog()` only*: `{{emoji}}` inserts the emoji
- *`.timeLog()` only*: `{{index}}` inserts a running index. (Needed to
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

### Have your formatter ignore the log statements
A common problem is that formatters like `prettier` split up the log statements
into multiple lines, making them hard to read and breaking `.removeLogs()`, which
relies on each line containing the marker emoji.

The simplest method to deal with this is to customize the log statement in your
configuration to include an ignore-comment: `/* prettier-ignore */` (and add the
marker to it as well, so it is included in the removal by `.removeLogs()`.)

```lua
require("chainsaw").setup {
	logStatements = {
		variableLog = {
			javascript = {
				"/* prettier-ignore */ // {{marker}}", -- adding this
				'console.log("{{marker}} {{var}}:", {{var}});',
			},
		},
	},
}
```

### Statusline
This function returns number of log statements *by nvim-chainsaw* in the current
buffer.

```lua
require("chainsaw.visuals.statusline").countInBuffer()
```

## Similar plugins
- [debugprint.nvim](https://github.com/andrewferrier/debugprint.nvim)
- [refactoring.nvim](https://github.com/ThePrimeagen/refactoring.nvim?tab=readme-ov-file#debug-features)
- [logsitter](https://github.com/gaelph/logsitter.nvim)
- [timber-.nvim](https://github.com/Goose97/timber.nvim)

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
