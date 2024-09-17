<!-- LTeX: enabled=false -->
# nvim-chainsaw 🪚
<!-- LTeX: enabled=true -->
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-chainsaw">
<img alt="badge" src="https://dotfyle.com/plugins/chrisgrieser/nvim-chainsaw/shield"/></a>

Speed up log creation. Create various kinds of language-specific log statements,
such as logs of variables, assertions, or stacktraces, timings, and more.

<https://github.com/chrisgrieser/nvim-chainsaw/assets/73286100/fa55ae24-deba-4fed-84e9-554d9a695ad9>

<!-- toc -->

- [Installation](#installation)
- [Built-in language support](#built-in-language-support)
- [Usage](#usage)
	* [List of commands](#list-of-commands)
	* [Smart variable identification](#smart-variable-identification)
- [Configuration](#configuration)
	* [Basic configuration](#basic-configuration)
	* [Add your own log statements](#add-your-own-log-statements)
	* [Have your formatter ignore the log statements](#have-your-formatter-ignore-the-log-statements)
- [Similar lua plugins](#similar-lua-plugins)
- [About the developer](#about-the-developer)

<!-- tocstop -->

## Installation
**Requirements**
- nvim 0.10 or higher.
- Optional for [smart variable identification](#smart-variable-identification):
  Treesitter parser for the respective languages.

```lua
-- lazy.nvim
{ "chrisgrieser/nvim-chainsaw" },

-- packer
use { "chrisgrieser/nvim-chainsaw" }
```

## Built-in language support
- JavaScript (and supersets)
- Python
- Lua (with special considerations for `nvim_lua`)
- Shell (and supersets)
- AppleScript
- Ruby
- Rust
- CSS (and supersets)

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

### List of commands

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
require("chainsaw").beepLog()

-- Sound-playing statement for audible debugging.
-- Depending on the type of log statement, the program may need
-- to run in a terminal that supports the system bell command. 
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

-- remove all log statements created by chainsaw
require("chainsaw").removeLogs()
```

These features can also be accessed with the user command `:ChainSaw`. Each
option corresponds to the commands above. For example, `:ChainSaw
variableLog` is same as `:lua require("chainsaw").variableLog()`.

When using lua functions, `variableLog`, `objectLog`, `typeLog`, and `assertLog`
can also be used in **visual mode** to use the visual selection instead of the
word under the cursor.

### Smart variable identification
When the variable under the cursor is an object with fields, `chainsaw` attempts
to automatically select the correct field. Note that this feature requires the
Treesitter parser of the respective language to be installed.

```lua
myVariable.myF[i]eld = "foobar"
-- prints: myVariable.myField

myVa[r]iable.myField = "foobar"
-- prints: myVariable
```

Filetypes currently supporting this feature:
- Lua
- Python
- JavaScript (and supersets)

*PRs adding support for more languages are welcome.*

## Configuration

### Basic configuration

```lua
-- default settings
require("chainsaw").setup {
	-- The marker should be a unique string, since lines with it are highlighted
	-- and since `removeLogs` will remove any line with it. Thus, emojis or
	-- strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- Highlight lines with the marker.
	-- lazy.nvim users:, you need to add `event = VeryLazy` to the plugin spec to
	-- have existing log statements highlighted as well.
	---@type string|false -- false to disable
	logHighlightGroup = "Visual",

	-- emojis used for `beepLog`
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

## Similar lua plugins
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
