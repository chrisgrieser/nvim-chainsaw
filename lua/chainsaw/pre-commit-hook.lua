local M = {}

local u = require("chainsaw.utils")
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
	local isInGitRepo = vim.system({ "git", "rev-parse", "--is-inside-work-tree" }):wait().code == 0
	if not gitRoot or not isInGitRepo then return end

	-- GUARD already installed
	local hookPath = vim.fs.normalize(gitRoot .. "/" .. config.preCommitHook.hookPath)
	local hookFile = vim.fs.normalize(hookPath .. "/pre-commit")
	if vim.uv.fs_stat(hookFile) then return end

	-- GUARD already has another pre-commit hook
	local out = vim.system({ "git", "config", "--get", "core.hooksPath" }):wait()
	local hasHookConfig = out.code == 0
	if hasHookConfig then
		local currentHookPath = vim.fs.normalize(vim.trim(out.stdout))
		local isRelative = not vim.startswith(currentHookPath, "/")
		if isRelative then currentHookPath = vim.fs.normalize(gitRoot .. "/" .. currentHookPath) end
		local hookPathExists = vim.uv.fs_stat(currentHookPath) ~= nil
		if hookPathExists then return end
	end

	-- GUARD ignored directories
	local ignored = vim.iter(config.preCommitHook.dontInstallInDirs):any(function(dirOrGlob)
		dirOrGlob = vim.fs.normalize(dirOrGlob)
		return vim.glob.to_lpeg(dirOrGlob):match(gitRoot)
	end)
	if ignored then return end

	-- GUARD not in nvim config itself, since user can have customized `marker`
	if config.preCommitHook.notInNvimConfigDir then
		local nvimConfigPath = vim.fn.stdpath("config") --[[@as string]]
		local isInNvimConfig = vim.startswith(vim.api.nvim_buf_get_name(0), nvimConfigPath)
		if isInNvimConfig then return end
	end

	-----------------------------------------------------------------------------

	-- setup hook
	local hookContent = config.preCommitHook.hookContent:format(config.marker)

	local args = { "git", "config", "core.hooksPath", config.preCommitHook.hookPath }
	local result = vim.system(args):wait()
	if result.code ~= 0 then
		u.warn("Could not install pre-commit hook: " .. result.stderr)
		return
	end

	vim.fn.mkdir(hookPath, "p")

	writeFile(vim.fs.normalize(hookPath .. "/.gitignore"), "*") -- gitignore the hook file
	writeFile(hookFile, hookContent)
	vim.fn.setfperm(hookFile, "rwxr-xr-x") -- make it executable (chmod 755)

	-- notify
	if config.preCommitHook.notifyOnInstall then u.info("Installed pre-commit hook.") end
end

--------------------------------------------------------------------------------
return M
