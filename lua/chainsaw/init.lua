local rw = require("chainsaw.read-write-lines")
local getVar = require("chainsaw.variable-identification").getVar

local M = {}
local function normal(cmdStr) vim.cmd.normal { cmdStr, bang = true } end
--------------------------------------------------------------------------------

---@param newConfig? pluginConfig
function M.setup(newConfig) require("chainsaw.config").setup(newConfig) end

--------------------------------------------------------------------------------

function M.messageLog()
	local config = require("chainsaw.config").config
	local logLines = rw.getTemplateStr("messageLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker })

	-- goto insert mode at correct location
	normal('f";')
	vim.cmd.startinsert()
end

function M.variableLog()
	local config = require("chainsaw.config").config
	local varname = getVar()
	local logLines = rw.getTemplateStr("variableLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker, varname, varname })
end

function M.objectLog()
	local config = require("chainsaw.config").config
	local varname = getVar()
	local logLines = rw.getTemplateStr("objectLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker, varname, varname })
end

function M.stacktraceLog()
	local config = require("chainsaw.config").config
	local logLines = rw.getTemplateStr("stacktraceLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker })
end

function M.assertLog()
	local config = require("chainsaw.config").config
	local varname = getVar()
	local logLines = rw.getTemplateStr("assertLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { varname, config.marker, varname })
	normal("f,") -- goto the comma to edit the condition
end

function M.beepLog()
	local config = require("chainsaw.config").config
	local logLines = rw.getTemplateStr("beepLog", config.logStatements)
	if not logLines then return end

	if not vim.b.beepLogIdx then vim.b["beepLogIdx"] = 0 end
	-- `math.fmod()` is lua's modulus
	vim.b["beepLogIdx"] = math.fmod(vim.b.beepLogIdx, #config.beepEmojis) + 1
	local emoji = config.beepEmojis[vim.b.beepLogIdx]

	rw.appendLines(logLines, { config.marker, emoji })
end

function M.timeLog()
	local config = require("chainsaw.config").config
	if vim.b.timeLogStart == nil then vim.b.timeLogStart = true end

	local startOrStop = vim.b.timeLogStart and "timeLogStart" or "timeLogStop"
	local logLines = rw.getTemplateStr(startOrStop, config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker })

	vim.b.timeLogStart = not vim.b.timeLogStart
end

function M.debugLog()
	local config = require("chainsaw.config").config
	local logLines = rw.getTemplateStr("debugLog", config.logStatements)
	if not logLines then return end
	rw.appendLines(logLines, { config.marker })
end

function M.removeLogs()
	local config = require("chainsaw.config").config
	local numOfLinesBefore = vim.api.nvim_buf_line_count(0)

	-- GUARD
	if config.marker == "" then
		vim.notify("No marker set.", vim.log.levels.ERROR, { title = "Chainsaw" })
		return
	end

	-- escape for vim regex, in case `[]()` are used in the marker
	local toRemove = config.marker:gsub("([%[%]()])", "\\%1")
	vim.cmd(("silent global/%s/delete"):format(toRemove))
	vim.cmd.nohlsearch()

	-- notify on number of lines removed
	local linesRemoved = numOfLinesBefore - vim.api.nvim_buf_line_count(0)
	local msg = ("Removed %s lines."):format(linesRemoved)
	if linesRemoved == 1 then msg = msg:sub(1, -3) .. "." end -- 1 = singular
	vim.notify(msg, vim.log.levels.INFO, { title = "Chainsaw" })

	-- reset
	vim.b.timelogStart = nil
end

--------------------------------------------------------------------------------

-- CREATE USER COMMANDS
local commandsExceptSetup = vim.tbl_filter(function(cmd) return cmd ~= "setup" end, vim.tbl_keys(M))

vim.api.nvim_create_user_command(
	"ChainSaw",
	function(opts) M[opts.args]() end,
	{ nargs = 1, complete = function() return commandsExceptSetup end }
)

--------------------------------------------------------------------------------
return M
