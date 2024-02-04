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
- [Configuration](#configuration)
- [Add your own log statements](#add-your-own-log-statements)
- [Credits](#credits)

<!-- tocstop -->

## Installation

```lua
-- lazy.nvim
{ "chrisgrieser/nvim-chainsaw" },

-- packer
use { "chrisgrieser/nvim-chainsaw" }
```

## Built-in language support
- JavaScript / TypeScript / TypeScriptReact
- Lua
- Python
- Shell
- AppleScript
- CSS / SCSS
- Ruby
- Rust

Not every language supports every type of log statement. For details on what is
supported, see [log-statements-data.lua](./lua/chainsaw/log-statements-data.lua).

> [!NOTE]
> In languages like CSS with no log statements, `nvim-chainsaw` simply uses
> similar statements with debugging purposes, such as `outline: 2px solid red
> !important;` to quickly assess whether a selector is correct or not.

## Usage
The plugin offers various types of log statements. Bind keymaps for the ones you
want to use.

```lua
-- create log statement, and position the cursor to enter a message
require("chainsaw").messageLog()

-- log the name and value of the a variable
-- normal mode: treesitter node or word under cursor, visual mode: selection
require("chainsaw").variableLog()

-- like variableLog, but with syntax specific to inspect an object, such as
-- `console.log(JSON.stringify(foobar))` in javascript
require("chainsaw").objectLog()

-- assertion statement
require("chainsaw").assertLog()

-- Minimal log statement, with an emoji for differentiation. Intended for
-- structures like if/else, to quickly glance whether a condition was triggered
-- or not. (Inspired by AppleScript's `beep` command.)
require("chainsaw").beepLog()

-- 1. call adds a statement that measures the time
-- 2. call adds a statement that logs the time since
require("chainsaw").timeLog()

-- debug statements like `debugger` in javascript or `breakpoint()` in python
require("chainsaw").debugLog()

-- remove all log statements created by chainsaw
require("chainsaw").removeLogs()
```

## Configuration

```lua
-- default settings
require("chainsaw").setup ({
	-- The marker should be a unique string, since `.removeLogs()` will remove
	-- any line with it. Emojis or strings like "[Chainsaw]" are recommended.
	marker = "🪚",

	-- emojis used for `.beepLog()`
	beepEmojis = { "🔵", "🟩", "⭐", "⭕", "💜", "🔲" },
})
```

## Add your own log statements
Custom log statements are added in the `setup()` call. The values are formatter
lua strings, meaning `%s` is a placeholder that is dynamically replaced
with the actual value. See
[log-statements-data.lua](./lua/chainsaw/log-statements-data.lua) for examples.

PRs adding log statements for more languages are welcome.

```lua
require("chainsaw").setup ({
	logStatements = {
		messageLog = {
			javascript = 'console.log("%s ");',
			otherFiletype = … -- <-- add the statement for your filetype here
		},
		variableLog = {
			javascript = 'console.log("%s %s:", %s);',
			otherFiletype = … -- <-- add the statement for your filetype here
		},
		-- the same way for the other statement types
	},
})
```

## Credits
<!-- vale Google.FirstPerson = NO -->
__About Me__  
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

__Blog__  
I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

__Profiles__  
- [reddit](https://www.reddit.com/user/pseudometapseudo)
- [Discord](https://discordapp.com/users/462774483044794368/)
- [Academic Website](https://chris-grieser.de/)
- [Twitter](https://twitter.com/pseudo_meta)
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
