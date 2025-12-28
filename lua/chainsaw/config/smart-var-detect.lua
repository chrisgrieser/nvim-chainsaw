local M = {}
--------------------------------------------------------------------------------

---The config should map a filetype to a function that takes the node under
---the cursor and returns another node that should be used instead.
---@type table<string, fun(node: TSNode): TSNode?>
M.ftConfig = {
	lua = function(node)
		if not node:parent() then return node end

		local onField = node:parent():type() == "dot_index_expression"
			and (node:prev_named_sibling() ~= nil) -- not for the first field
		local onArrayNumber = node:parent():type() == "bracket_index_expression"
		if onField or onArrayNumber then return node:parent() end

		local onMethod = node:parent():type() == "method_index_expression"
			and (node:prev_named_sibling() ~= nil) -- not for the first field
		if onMethod then return node:parent():parent() end
		local onColonOfMethod = node:type() == "method_index_expression"
		if onColonOfMethod then return node:parent() end
		local cursorParensOfMethod = node:type() == "arguments"
			and (node:prev_named_sibling():type() == "method_index_expression")
		if cursorParensOfMethod then return node:prev_named_sibling():parent() end

		return node
	end,
	python = function(node)
		local onField = node:type():find("^string_")
			and node:parent()
			and node:parent():parent()
			and node:parent():parent():type() == "subscript"
		if onField then node = node:parent():parent() end

		local onAttribute = node
			and node:type() == "identifier"
			and node:parent()
			and node:parent():type() == "attribute"
		if onAttribute and node then node = node:parent() end
		return node
	end,
	javascript = function(node)
		local onField = node:type() == "property_identifier"
		if onField then node = node:parent() end
		return node
	end,
}

require("chainsaw.config.config").supersetInheritance(M.ftConfig)

--------------------------------------------------------------------------------
return M
