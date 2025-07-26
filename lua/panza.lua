local M = {}

local chat = require("chat")

local config = {
	root_path = "", -- root forlder of plugin folder
	agent_path = "", -- python agent folder path
	venv = "",      -- python venv folder path
	python = "",    -- python3 venv path
	pip = "",       -- pip venv path
}


local function install_requirements()
	-- local output = io.popen(config.pip .. " install -r requirements.txt")
	-- local output = io.popen(config.python .. " -m pip check"):read("*a")
	-- print(output)
	-- print("hhh")
	if vim.fn.filereadable(vim.fs.joinpath(config.root_path, "agent", "requirements.txt")) == 1 then
		-- local output = io.popen(config.pip .. " install -r requirements.txt"):read("*a")
		local output = io.popen(config.pip .. " show huggingface_hub"):read("*a")
		if not vim.startswith(output, "Name") then
			io.popen(config.pip .. " install huggingface_hub"):read("*a")
			install_requirements()
		else
			print("Alles gutte")
		end
	end
end

local create_python_venv = function()
	local output = os.execute("python3 -m venv " .. config.venv)
	if not output == 0 then
		return
	end
	config.python = vim.fs.joinpath(config.venv, "bin", "python3")
	config.pip = vim.fs.joinpath(config.venv, "bin", "pip")
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
	config.venv = vim.fs.joinpath(config.root_path, "agent", "venv")
	if vim.fn.isdirectory(config.venv) == 1 then
		print("Assigning config paths")
		config.python = vim.fs.joinpath(config.venv, "bin", "python3")
		config.pip = vim.fs.joinpath(config.venv, "bin", "pip")
		install_requirements()
	else
		create_python_venv()
	end
end

M.load_module = function()
	local test_string = { text = "Sancho is ready" }
	local status, result = pcall(vim.json.encode, test_string)
	test_dependencies()
	if not status then
		print("Error decoding json: " .. result)
	else
		print(result)
		chat.main_loop(config.python, { "-u", "-i", vim.fs.joinpath(config.agent_path, "main.py") })
	end
end

M.load_module()

M.setup = function() -- todo
end
return M
