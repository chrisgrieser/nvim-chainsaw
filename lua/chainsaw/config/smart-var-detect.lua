local M = {}
--------------------------------------------------------------------------------

---The config should map a filetype to a function that takes the node under
---the cursor and returns another node that should be used instead.
---@type table<string, fun(node: TSNode): TSNode?>
M.ftConfig = {
	lua = function(node)
		local cursorOnDot = node:type() == "dot_index_expression"
		local cursorOnField = node:parent()
			and node:parent():type() == "dot_index_expression"
			and node:prev_named_sibling()
		if cursorOnDot then
			node = node:parent()
		elseif cursorOnField then
			node = node:parent():parent()
		end
		return node
	end,
	python = function(node)
		local cursorOnField = node:type():find("^string_") and node:parent()
		if cursorOnField then node = node:parent():parent() end
		return node
	end,
	javascript = function(node)
		local cursorOnField = node:type() == "property_identifier"
		if cursorOnField then node = node:parent() end
		return node
	end,
}

-- superset inheritance
setmetatable(M.ftConfig, {
	__index = function(type, key)
		local supersets = require("chainsaw.config.config").config.supersets
		local targetFt = supersets[key]
		if not targetFt then return nil end
		return type[targetFt]
	end,
})

--------------------------------------------------------------------------------
return M
