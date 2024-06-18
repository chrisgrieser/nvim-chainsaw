<!-- LTeX: enabled=false -->
# nvim-chainsaw 🪚
<!-- LTeX: enabled=true -->
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-chainsaw">
<img alt="badge" src="https://dotfyle.com/plugins/chrisgrieser/nvim-chainsaw/shield"/></a>

Speed up log creation. Create various kinds of language-specific log statements,
such as logs of variables, assertions, or time-measuring.

<https://github.com/chrisgrieser/nvim-chainsaw/assets/73286100/fa55ae24-deba-4fed-84e9-554d9a695ad9>

<!-- toc -->

- [Installation](#installation)
- [Built-in language support](#built-in-language-support)
- [Usage](#usage)
	* [List of Commands](#list-of-commands)
	* [Smart Variable Identification](#smart-variable-identification)
- [Configuration](#configuration)
	* [Basic Configuration](#basic-configuration)
	* [Add your own log statements](#add-your-own-log-statements)
	* [Have your formatter ignore the log statements](#have-your-formatter-ignore-the-log-statements)
- [Similar Lua Plugins](#similar-lua-plugins)
- [Credits](#credits)

<!-- tocstop -->

## Installation

```lua
-- lazy.nvim
{ "chrisgrieser/nvim-chainsaw" },

-- packer
use { "chrisgrieser/nvim-chainsaw" }
```

It is recommended to use **nvim 0.9+** and install the **Treesitter parsers**
for the respective languages, as this improves variable identification. The
plugin falls back to the word under the cursor if those requirements are
not met.

## Built-in language support
- JavaScript (and: JavaScriptReact / TypeScript / TypeScriptReact / Vue / Svelte)
- Python
- Lua (with special considerations for `nvim_lua`)
- Shell (and: zsh / bash / fish)
- AppleScript
- Ruby
- Rust
- CSS (and: SCSS / LESS)
- Justfiles

Not every language supports every type of log statement. For details on what is
supported, see [log-statements-data.lua](./lua/chainsaw/log-statements-data.lua).

> [!NOTE]
> For non-scripting languages like CSS, `nvim-chainsaw` uses statements such as
> `outline: 2px solid red !important;` that are the closest thing to logging
> you have.

## Usage
The plugin offers various types of log statements. Bind keymaps for the ones you
want to use.

All operations are dot-repeatable.

### List of Commands

```lua
-- log the name and value of the a variable
-- normal mode: treesitter node or word under cursor, visual mode: selection
require("chainsaw").variableLog()

-- like variableLog, but with syntax specific to inspect an object, such as
-- `console.log(JSON.stringify(foobar))` in javascript
require("chainsaw").objectLog()

-- assertion statement for the variable under the cursor
require("chainsaw").assertLog()

-- create log statement, and position the cursor to enter a message
require("chainsaw").messageLog()

-- prints the stacktrace of the current call
require("chainsaw").stacktraceLog()

-- Minimal log statement, with an emoji for differentiation. Intended for
-- control flow inspection, i.e. to quickly glance whether a condition was
-- triggered or not. (Inspired by AppleScript's `beep` command.)
require("chainsaw").beepLog()

-- 1st call: start measuring the time
-- 2nd call: logs the time duration since
require("chainsaw").timeLog()

-- debug statements like `debugger` in javascript or `breakpoint()` in python
require("chainsaw").debugLog()

---------------------------------------------------

-- remove all log statements created by chainsaw
require("chainsaw").removeLogs()
```

These features can also be accessed with the user command `:ChainSaw`.

Each option corresponds to the commands above. For example, `:ChainSaw
variableLog` is same as `:lua require("chainsaw").variableLog()`.

### Smart Variable Identification
When the variable under the cursor is an object with fields, `chainsaw` attempts
to automatically select the correct field.

```lua
myVariable.myF[i]eld = "foobar"
-- prints: myVariable.myField

myVa[r]iable.myField = "foobar"
-- prints: myVariable
```

Filetypes currently supporting this feature:
- Lua
- Python
- JavaScript / TypeScript / TypeScriptReact / Vue / Svelte

PRs adding support for more languages are welcome. The relevant code section [can
be found here](https://github.com/chrisgrieser/nvim-chainsaw/blob/f59f590858f2b0a2f4bf1005eb7e0472141f42f1/lua/chainsaw/variable-identification.lua#L28-L42).

## Configuration

### Basic Configuration

```lua
-- default settings
require("chainsaw").setup {
	-- The marker should be a unique string, since `.removeLogs()` will remove
	-- any line with it. Emojis or strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- emojis used for `.beepLog()`
	beepEmojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },
}
```

### Add your own log statements
Custom log statements are added in the `setup()` call. The values are formatted
lua strings, meaning `%s` is a placeholder that is dynamically replaced
with the actual value. See
[log-statements-data.lua](./lua/chainsaw/log-statements-data.lua) for examples.

PRs adding log statements for more languages are welcome.

```lua
require("chainsaw").setup ({
	logStatements = {
		variableLog = {
			javascript = 'console.log("%s %s:", %s);',
			otherFiletype = … -- <-- add the statement for your filetype here
		},
		-- the same way for the other log statement operations
	},
})
```

### Have your formatter ignore the log statements
A common problem is that formatters like `prettier` break up the log
statements, making them hard to read and also breaking `removeLogs()`, which
relies on each line containing the marker emoji.

The simplest method to deal with this is to customize the log statement in
your configuration to include `/* prettier-ignore */`:

```lua
require("chainsaw").setup {
	logStatements = {
		variableLog = {
			javascript = {
				"/* prettier-ignore */ // %s", -- adding this line
				'console.log("%s %s:", %s);',
			},
		},
	},
}
```

## Similar Lua Plugins
- [debugprint.nvim](https://github.com/andrewferrier/debugprint.nvim)
- [refactoring.nvim](https://github.com/ThePrimeagen/refactoring.nvim?tab=readme-ov-file#debug-features)
- [logsitter](https://github.com/gaelph/logsitter.nvim)

The other plugins are more feature-rich, while `nvim-chainsaw` tries to
achieve the core functionality in a far more lightweight manner to keep
maintenance minimal.

<!-- vale Google.FirstPerson = NO -->
## About the developer
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

- [Academic Website](https://chris-grieser.de/)
- [Mastodon](https://pkm.social/@pseudometa)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'><img
	height='36'
	style='border:0px;height:36px;'
	src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
	border='0'
	alt='Buy Me a Coffee at ko-fi.com'
/></a>
