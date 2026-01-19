local M = {}
--------------------------------------------------------------------------------

---The config should map a filetype to a function that takes the node under
---the cursor and returns a number representing the shift in line number where
---the log statement should be inserted instead. For example, `-1` means to
---above the current line, and `0` (the default) means below the current line.
---@type table<string, fun(node: TSNode): integer?>
M.ftConfig = {
	lua = function(node)
		-- return statement
		local parent = node:parent()
		while parent and not parent:type():find("function") do
			if parent:type() == "return_statement" then
				return -1
			end
			parent = parent:parent()
		end

		-- multiline assignment
		local grandparent = node:parent() and node:parent():parent()
		if grandparent and grandparent:type() == "assignment_statement" then
			local assignmentExtraLines = grandparent:end_() - grandparent:start()
			return assignmentExtraLines
		end
	end,
	javascript = function(node)
		local parent = node:parent()
		if not parent then
			return
		end

		-- return statement
		local inReturnStatement = parent:type() == "return_statement"
			or (parent:parent() and parent:parent():type() == "return_statement")
		if inReturnStatement then
			return -1
		end

		-- multiline assignment
		local isAssignment = parent:type() == "variable_declarator"
			or parent:type() == "assignment_expression"
		if isAssignment then
			local assignmentExtraLines = parent:end_() - parent:start()
			return assignmentExtraLines
		end

		-- multiline function parameter, see #28
		local isFunctionParam = vim.endswith(parent:type(), "parameter")
		local paramList = parent:parent()
		if isFunctionParam and paramList then
			local paramLnum = parent:start()
			local paramExtraLines = paramList:end_() - paramLnum
			return paramExtraLines
		end
	end,
	python = function(node)
		local parent = node:parent()
		while parent do
			local type = parent:type()
			if type == "function_definition" or type == "async_function_definition" then
				break
			end
			parent = parent:parent()
		end
		if not parent then
			return
		end

		local body = parent:field("body")[1]
		if not body then
			return
		end

		local firstChild = body:named_child(0)
		if not firstChild then
			return
		end

		-- check for docstrings
		if firstChild:type() == "expression_statement" then
			local expression = firstChild:child(0)
			if expression and expression:type() == "string" then
				local _, _, endRow, _ = firstChild:range()
				local startRow, _, _, _ = node:range()
				if startRow > endRow then
					return
				end
				return endRow - startRow
			end
		end
	end,
}

require("chainsaw.config.config").supersetInheritance(M.ftConfig)

--------------------------------------------------------------------------------
return M
