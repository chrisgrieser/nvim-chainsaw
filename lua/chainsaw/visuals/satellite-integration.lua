-- DOCS https://github.com/lewis6991/satellite.nvim/blob/main/HANDLERS.md#handlers

-- Disable for the nvim-type check test, since it does not have access to
-- `lazydev.nvim`, and thus does not know about satellite.nvim's types.
---@diagnostic disable: undefined-doc-name
--------------------------------------------------------------------------------

local config = require("chainsaw.config.config").config.visuals.nvimSatelliteIntegration
local satelliteInstalled, satelliteHandlers = pcall(require, "satellite.handlers")

if not satelliteInstalled or not config.enabled then return end

--------------------------------------------------------------------------------

local ns = vim.api.nvim_create_namespace("chainsaw.markers")

---@type Satellite.Handler
local handler = {
	name = "chainsaw",
	ns = vim.api.nvim_create_namespace("chainsaw.satellite-integration"),
	config = {
		enable = true, -- is disabled via chainsaw-config, not here
		overlap = not config.leftOfScrollbar,
		priority = config.priority,
	},
	enabled = function()
		local chainsawExtmarks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
		return #chainsawExtmarks > 0
	end,
	update = function(bufnr, winid)
		local chainsawExtmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
		local satelliteMarks = vim
			.iter(chainsawExtmarks)
			:filter(function(extm) return not extm[4].invalid end) -- exclude deleted extmarks
			:map(function(extm)
				local rowWithMarker = extm[2] + 1
				local scrollbarPos, _ = require("satellite.util").row_to_barpos(winid, rowWithMarker)

				---@type Satellite.Mark
				local mark = {
					pos = scrollbarPos,
					highlight = config.hlgroup,
					symbol = config.icon,
				}
				return mark
			end)
			:totable()
		return satelliteMarks
	end,
}

satelliteHandlers.register(handler)
