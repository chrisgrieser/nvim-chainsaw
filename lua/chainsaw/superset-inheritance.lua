local M = {}
--------------------------------------------------------------------------------

---@param data logStatementData
---@return logStatementData
function M.insert(data)
	local logTypes = vim.tbl_keys(data)

	-- JS supersets inherit from `typescript`, and in turn `typescript` form
	-- `javascript`, if it set itself.
	local jsSupersets = { "typescriptreact", "javascriptreact", "vue", "svelte" }
	for _, logType in ipairs(logTypes) do
		if not data[logType].typescript then data[logType].typescript = data[logType].javascript end
		for _, lang in ipairs(jsSupersets) do
			data[logType][lang] = data[logType].typescript
		end
	end

	-- shell supersets inherit from `sh`, if they have no config of their own.
	local shellSupersets = { "bash", "zsh", "fish", "nu" }
	for _, logType in ipairs(logTypes) do
		for _, lang in ipairs(shellSupersets) do
			if not data[logType][lang] then data[logType][lang] = data[logType].sh end
		end
	end

	-- CSS supersets inherit from `css`, if they have no config of their own.
	local cssSupersets = { "scss", "less", "sass" }
	for _, logType in ipairs(logTypes) do
		for _, lang in ipairs(cssSupersets) do
			if not data[logType][lang] then data[logType][lang] = data[logType].css end
		end
	end

	-- `nvim-lua` inherits from `lua`, if it has no config of its own.
	for _, logType in ipairs(logTypes) do
		if not data[logType].nvim_lua then data[logType].nvim_lua = data[logType].lua end
	end
	return data
end

--------------------------------------------------------------------------------
return M
