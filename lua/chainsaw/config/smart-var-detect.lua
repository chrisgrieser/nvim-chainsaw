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
		local cursorOnField = node:type():find("^string_")
			and node:parent()
			and node:parent():parent()
			and node:parent():parent():type() == "subscript"
		if cursorOnField then node = node:parent():parent() end

		local cursorOnAttribute = node
			and node:type() == "identifier"
			and node:parent()
			and node:parent():type() == "attribute"
		if cursorOnAttribute and node then node = node:parent() end
		return node
	end,
	javascript = function(node)
		local cursorOnField = node:type() == "property_identifier"
		if cursorOnField then node = node:parent() end
		return node
	end,
}

require("chainsaw.config.config").supersetInheritance(M.ftConfig)

--------------------------------------------------------------------------------
return M
