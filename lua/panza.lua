local M = {}

local chat = require("chat")

local config = {
	root_path = "", -- root forlder of plugin folder
	agent_path = "", -- python agent folder path
	pip_venv = "",  -- python venv folder path
	uv_venv = "",
	python = "",    -- python3 venv path
	pip = "",       -- pip venv path
}


local function install_requirements()
	if vim.fn.filereadable(vim.fs.joinpath(config.root_path, "agent", "requirements.txt")) == 1 then
		local output = io.popen(config.pip .. " install uv"):read("*a")
		-- local output = io.popen(config.pip .. " show huggingface_hub"):read("*a")
		-- if not vim.startswith(output, "Name") then
		-- 	io.popen(config.pip .. " install huggingface_hub"):read("*a")
		-- 	install_requirements()
		-- end
	end
end

local create_python_venv = function()
	local output = os.execute("python3 -m venv " .. config.pip_venv)
	if not output == 0 then
		return
	end
	config.python = vim.fs.joinpath(config.pip_venv, "bin", "python3")
	config.pip = vim.fs.joinpath(config.pip_venv, "bin", "pip")
	install_requirements()
end


local test_dependencies = function()
	-- Finding root_path of this plugin
	local mod_path = vim.loader.find("panza")[1].modpath
	for dir in vim.fs.parents(mod_path) do
		if vim.fn.filereadable(vim.fs.joinpath(dir, "lua", "panza.lua")) == 1 then
			config.root_path = dir
			break
		end
	end
	config.agent_path = vim.fs.joinpath(config.root_path, "agent")
	-- Checking existence of python venv
	config.pip_venv = vim.fs.joinpath(config.root_path, "agent", ".pip")
	if vim.fn.isdirectory(config.pip_venv) == 1 then
		config.python = vim.fs.joinpath(config.pip_venv, "bin", "python3")
		config.pip = vim.fs.joinpath(config.pip_venv, "bin", "pip")
		install_requirements()
	else
		create_python_venv()
	end
end

---@class panza.Options
---@field hf_api_key string: hugging face API key

---Initialize application
---@param opts panza.Options
M.load_module = function(opts)
	local opts = opts or {}
	if not opts.hf_api_key then
		print("Missing hf_api_key option. Module was not loaded.")
		return
	end
	test_dependencies()
	vim.api.nvim_create_user_command("OpenChat", function()
		chat.start_chat(config.python, config.agent_path, opts.hf_api_key)
	end, {})
end

M.setup = function() -- todo
end
return M
