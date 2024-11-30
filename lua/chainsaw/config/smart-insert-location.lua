local M = {}
--------------------------------------------------------------------------------

---The config should map a filetype to a function that takes the node under
---the cursor and returns a number representing the shift in line number where
---the log statement should be inserted instead. For example, `-1` means to
---insert above the current line, and `0` means below the current line. If not
---return value is provided, will return below the current line.
---@type table<string, fun(node: TSNode): integer?>
M.ftConfig = {
	lua = function(node)
		local parent = node:parent()
		local grandparent = parent and parent:parent()
		if not parent or not grandparent then return end

		-- return statement
		local exprNode
		if parent:type() == "expression_list" then exprNode = parent end
		if grandparent:type() == "expression_list" then exprNode = grandparent end
		if exprNode and exprNode:parent() and exprNode:parent():type() == "return_statement" then
			return -1
		end

		-- multiline assignment
		if grandparent:type() == "assignment_statement" then
			local assignmentExtraLines = grandparent:end_() - grandparent:start()
			return assignmentExtraLines
		end
	end,
	javascript = function(node)
		local parent = node:parent()
		if not parent then return end

		-- return statement
		local inReturnStatement = parent:type() == "return_statement"
			or (parent:parent() and parent:parent():type() == "return_statement")
		if inReturnStatement then return -1 end

		-- multiline assignment
		local isAssignment = parent:type() == "variable_declarator"
			or parent:type() == "assignment_expression"
		if isAssignment then
			local assignmentExtraLines = parent:end_() - parent:start()
			return assignmentExtraLines
		end
	end,
}

require("chainsaw.config.config").supersetInheritance(M.ftConfig)

--------------------------------------------------------------------------------
return M
