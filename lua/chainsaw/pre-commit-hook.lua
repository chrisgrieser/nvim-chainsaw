local M = {}
-------------------------------------------------------------------------------

---@param path string
---@param content string
local function writeFile(path, content)
	local file = io.open(path, "w")
	if file then
		file:write(content)
		file:close()
	end
end

--------------------------------------------------------------------------------

function M.install()
	local config = require("chainsaw.config.config").config
	if not config.preCommitHook.enabled then return end

	-- GUARD not in a git repo
	local gitRoot = vim.fs.root(0, ".git")
	if not gitRoot then return end

	-- GUARD already installed
	local hookPath = vim.fs.normalize(gitRoot .. "/" .. config.preCommitHook.hookPath)
	local hookFile = vim.fs.normalize(hookPath .. "/pre-commit")
	if vim.uv.fs_stat(hookFile) then return end

	-- GUARD already has another pre-commit hook
	if config.preCommitHook.noHookOverride then
		local currentHookPath =
			vim.trim(vim.system({ "git", "config", "--get", "core.hooksPath" }):wait().stdout)
		local currentHookFile = vim.fs.normalize(gitRoot .. "/" .. currentHookPath .. "/pre-commit")
		if vim.uv.fs_stat(currentHookFile) then return end
	end

	-- GUARD ignored directories
	local ignored = vim.iter(config.preCommitHook.dontInstallInDirs):any(function(dirOrGlob)
		dirOrGlob = vim.fs.normalize(dirOrGlob)
		return vim.glob.to_lpeg(dirOrGlob):match(gitRoot)
	end)
	if ignored then return end

	-----------------------------------------------------------------------------

	-- setup hook
	local hookContent = config.preCommitHook.hookContent:format(config.marker)

	vim.system { "git", "config", "core.hooksPath", config.preCommitHook.hookPath }
	vim.fn.mkdir(hookPath, "p")

	writeFile(vim.fs.normalize(hookPath .. "/.gitignore"), "*") -- gitignore the hook file
	writeFile(hookFile, hookContent)
	vim.fn.setfperm(hookFile, "rwxr-xr-x") -- make it executable (chmod 755)

	-- notify
	if config.preCommitHook.notifyOnInstall then
		require("chainsaw.utils").info("Installed pre-commit hook.")
	end
end

--------------------------------------------------------------------------------
return M
