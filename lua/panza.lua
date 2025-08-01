local M = {}

local chat = require("chat")
local dependencies = require("dependencies")

---@class panza.Config
---@field root_path string: root foldder of plugin
---@field agent_path string: python agent folder
---@field pip_venv string: path to venv .pip folder of pip
---@field uv string: path to uv package manager inside pip_venv
---@field python string: path to python inside pip_venv
---@field pip string: path to pip inside pip_venv

---@type panza.Config
local config = {
	root_path = "",
	agent_path = "",
	pip_venv = "", -- python venv folder path
	uv = "",
	python = "",  -- python3 venv path
	pip = "",     -- pip venv path
}



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
	config = dependencies.run_check()
	if config == nil then
		print("Checking dependencies was not successful")
	else
		vim.api.nvim_create_user_command("OpenChat", function()
			chat.start_chat(config.uv, config.agent_path, opts.hf_api_key)
		end, {})
	end
end

return M
