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
		-- return statement
		local exprNode
		if node:parent():type() == "expression_list" then
			exprNode = node:parent()
		elseif node:parent():parent():type() == "expression_list" then
			exprNode = node:parent()
		end
		if exprNode and exprNode:parent():type() == "return_statement" then return -1 end

		-- multiline assignment
		if node:parent():parent():type() == "assignment_statement" then
			local assignment = assert(node:parent():parent())
			local lineCountOfAssignment = assignment:end_() - assignment:start()
			return lineCountOfAssignment
		end
	end,
	javascript = function(node)
		-- return statement
		local inReturnStatement = node:parent():type() == "return_statement"
			or node:parent():parent():type() == "return_statement"
		if inReturnStatement then return -1 end

		-- multiline assignment
		local isAssignment = node:parent():type() == "variable_declarator"
			or node:parent():type() == "assignment_expression"
		if isAssignment then
			local declarator = assert(node:parent())
			local lineCountOfAssignment = declarator:end_() - declarator:start()
			return lineCountOfAssignment
		end
	end,
}

require("chainsaw.config.config").supersetInheritance(M.ftConfig)

--------------------------------------------------------------------------------
return M
