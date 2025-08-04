local M = {}

local chat = require("chat")

---@type panza.Config
local config = {
	root_path = "",
	agent_path = "",
	pip_venv = "",
	uv = "",
	python = "",
	pip = "",
	hf_api_key = ""
}

local function err(msg)
	vim.notify(msg, vim.log.levels.ERROR)
end

local function check_if_python()
	local python_check = vim.fn.executable("python3")
	if python_check == 0 then
		err("Missing Python3")
		return false
	end
	return true
end

local function set_plugin_root_dir()
	local mod_path = vim.loader.find("panza")[1].modpath
	for dir in vim.fs.parents(mod_path) do
		if vim.fn.filereadable(vim.fs.joinpath(dir, "lua", "panza.lua")) == 1 then
			config.root_path = dir
			return true
		end
	end
	if not config.root_path then
		err("Was not able to find root_path of PANZA plugin")
		return false
	end
end

local function set_python_agent_dir()
	local agent_path = vim.fs.joinpath(config.root_path, "agent")
	if vim.fn.isdirectory(agent_path) ~= 1 then
		err("Was not able to find agent dir of PANZA plugin")
		return false
	end
	config.agent_path = agent_path
	return true
end

local function setup_pip_venv()
	local result = vim.fn.system({ "python3", "-m", "venv", vim.fs.joinpath(config.agent_path, ".pip") })
	if vim.v.shell_error ~= 0 then
		err("Creating of venv .pip was not successful")
		return false
	end
	config.pip_venv = vim.fs.joinpath(config.agent_path, ".pip")
	return true
end

local function set_pip_venv()
	local pip_venv_path = vim.fs.joinpath(config.agent_path, ".pip")
	if vim.fn.isdirectory(pip_venv_path) ~= 1 then
		return setup_pip_venv()
	end
	config.pip_venv = pip_venv_path
	return true
end

local function set_pip()
	local pip_path = vim.fs.joinpath(config.pip_venv, "bin", "pip")
	if vim.fn.filereadable(pip_path) ~= 1 then
		err("Missing pip inside venv .pip in PANZA plugin")
		return false
	end
	config.pip = pip_path
	return true
end

local function install_dependencies()
	-- local result = vim.fn.system({ config.uv, "run", "--python", "3.11", "--directory", config.agent_path, "deps.py" })
	local stdin = vim.uv.new_pipe()
	local stdout = vim.uv.new_pipe()
	local stderr = vim.uv.new_pipe()
	local close_chat
	local args = { "run", "--python", "3.11", "--directory", config.agent_path, "deps.py" }

	local handle, pid = vim.uv.spawn(config.uv, {
		args = args,
		stdio = { stdin, stdout, strderr }
	}, close_chat)

	close_chat = function(code, signal)
		print("Code: " .. code)
		print("Signal: " .. signal)
		print("Deps closing")
		stdin:close()
		stdout:close()
		stderr:close()
		handle:close()
	end
	local n = 0
	stdout:read_start(function(err_p, data)
		assert(not err_p, err_p)
		vim.schedule(function()
			vim.api.nvim_create_user_command("OpenChat", function()
				chat.start_chat(config.uv, config.agent_path, config.hf_api_key)
			end, {})
			handle:kill("sigterm")
		end)
	end)
	stderr:read_start(function(err_p, data)
		assert(not err_p, err_p)
		if data then
			handle:close()
			err("Installation of python dependencies was not successful")
		end
	end)
	-- if vim.v.shell_error ~= 0 then
	-- 	err("Installation of python dependencies was not successful")
	-- 	return false
	-- end
	-- return true
end

local function setup_uv()
	local uv_path = vim.fs.joinpath(config.pip_venv, "bin", "uv")
	local result = vim.fn.system({ config.pip, "install", "uv" })
	if vim.v.shell_error ~= 0 then
		err("Instalation of uv was not successful")
		return false
	end
	config.uv = uv_path
	return install_dependencies()
end

local function set_uv()
	local uv_path = vim.fs.joinpath(config.pip_venv, "bin", "uv")
	if vim.fn.filereadable(uv_path) ~= 1 then
		vim.api.nvim_create_user_command("OpenChat", function()
			print("Installation of dependencies ongoing...")
		end, {})
		return setup_uv()
	end
	config.uv = uv_path
	vim.api.nvim_create_user_command("OpenChat", function()
		chat.start_chat(config.uv, config.agent_path, config.hf_api_key)
	end, {})
	return true
end


local deps_testing = {
	check_if_python,
	set_plugin_root_dir,
	set_python_agent_dir,
	set_pip_venv,
	set_pip,
	set_uv,
}

M.run_check = function(hf_api_key)
	config.hf_api_key = hf_api_key
	for _, func in ipairs(deps_testing) do
		func()
	end
end

return M
