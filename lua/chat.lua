local M = {}

local messenger = require("messenger")

local chat = {
	chat_w_win = -1,
	chat_w_buf = -1,
	input_w_win = -1,
	input_w_buf = -1,
}

local function set_chat_default()
	chat.chat_w_win = -1
	chat.chat_w_buf = -1
	chat.input_w_win = -1
	chat.input_w_buf = -1
end

local roles = {
	assistant = "Asistant:",
	user = "User:"
}


local function create_window_config(opts)
	local opts = opts or {}
	local width = vim.o.columns
	local height = vim.o.lines
	local chat_w_width = math.floor(width * 0.4)
	local chat_w_height = math.floor(height * 0.9) - 10
	local chat_w_column = width - chat_w_width
	local chat_w_row = math.floor((height - chat_w_height) / 2 - 5)
	local input_w_width = chat_w_width
	local input_w_height = 5
	local input_w_column = chat_w_column
	local input_w_row = chat_w_height + 5

	return {
		chat = {
			relative = "editor",
			width = chat_w_width,
			height = chat_w_height,
			col = chat_w_column,
			row = chat_w_row,
			style = "minimal",
			border = "rounded",
			title = "Chat",
			title_pos = "center"
		},
		input = {
			relative = "editor",
			width = input_w_width,
			height = input_w_height,
			col = input_w_column,
			row = input_w_row,
			style = "minimal",
			border = "rounded",
			title = "Enter your prompt",
			title_pos = "center"
		},
	}
end

---Converting buffer lines to string
---@param lines string[]
---@return string
local function parse_input(lines)
	local input_text = ""
	for _, value in pairs(lines) do
		input_text = input_text .. value .. "\n"
	end
	return vim.trim(input_text)
end

---Converting response content to lines
---@param text any
---@return string[]
local function parse_response(text)
	local lines = {}
	local separator = "\n"
	for str in string.gmatch(text, "([^" .. separator .. "]+)") do
		table.insert(lines, str)
	end
	return lines
end

local function open_float(opts)
	opts = opts or {}
	local buf = nil
	if vim.api.nvim_buf_is_valid(opts.buf) then
		buf = opts.buf
	else
		buf = vim.api.nvim_create_buf(false, true)
	end
	local win = vim.api.nvim_open_win(buf, true, opts.win_cfg)
	return buf, win
end

local function refresh()
	vim.api.nvim_set_option_value("modifiable", true, { buf = chat.chat_w_buf })
	local all_messages = messenger.get_all_messages()
	local lines = {}
	for _, message in pairs(all_messages) do
		local role = roles[message.role] or "Response:"
		table.insert(lines, role)
		local lines_from_text = parse_response(message.content)
		for _, line in pairs(lines_from_text) do
			table.insert(lines, line)
		end
		table.insert(lines, "")
	end
	vim.api.nvim_buf_set_lines(chat.chat_w_buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = chat.chat_w_buf })
	if #all_messages > 0 then
		local last_message_len = parse_response(all_messages[#all_messages].content)
		vim.api.nvim_win_set_cursor(chat.chat_w_win, { #lines - #last_message_len, 0 })
	end
end

local function chat_window()
	local chat_config = create_window_config().chat
	chat.chat_w_buf, chat.chat_w_win = open_float({ buf = -1, win_cfg = chat_config })
	vim.api.nvim_set_option_value("modifiable", false, { buf = chat.chat_w_buf })
	refresh()
end

local function input_window()
	local input_config = create_window_config().input
	chat.input_w_buf, chat.input_w_win = open_float({ buf = -1, win_cfg = input_config })


	vim.api.nvim_create_user_command("SendMessage", function()
		local lines = vim.api.nvim_buf_get_lines(chat.input_w_buf, 0, -1, false)
		local parsed_text = parse_input(lines)
		messenger.send_message(parsed_text)
		vim.api.nvim_buf_set_lines(chat.input_w_buf, 0, -1, false, {})
		vim.api.nvim_set_option_value("modifiable", false, { buf = chat.input_w_buf })
	end, {})
	vim.keymap.set("n", "<CR>", ":SendMessage<CR>", {})
end


local function reponse()
	refresh()
	vim.api.nvim_set_option_value("modifiable", true, { buf = chat.input_w_buf })
	vim.api.nvim_buf_set_lines(chat.input_w_buf, 0, -1, false, {})
end

local function toggle_chat()
	if not vim.api.nvim_win_is_valid(chat.chat_w_win) and not vim.api.nvim_win_is_valid(chat.input_w_win) then
		chat_window()
		input_window()
	else
		vim.api.nvim_win_hide(chat.chat_w_win)
		vim.api.nvim_win_hide(chat.input_w_win)
	end
end


local function close_chat()
	if vim.api.nvim_win_is_valid(chat.chat_w_win) then
		vim.api.nvim_win_close(chat.chat_w_win, true)
	end
	if vim.api.nvim_win_is_valid(chat.input_w_win) then
		vim.api.nvim_win_close(chat.input_w_win, true)
	end
	set_chat_default()
	messenger.close_process()
end

local function first_run()
	local loading_message = "Loading..."
	if vim.api.nvim_win_is_valid(chat.chat_w_win) and vim.api.nvim_win_is_valid(chat.input_w_win) then
		vim.api.nvim_set_option_value("modifiable", true, { buf = chat.chat_w_buf })
		vim.api.nvim_buf_set_lines(chat.chat_w_buf, 0, -1, false, { loading_message })
		vim.api.nvim_set_option_value("modifiable", false, { buf = chat.chat_w_buf })

		vim.api.nvim_buf_set_lines(chat.input_w_buf, 0, -1, false, { loading_message })
		vim.api.nvim_set_option_value("modifiable", false, { buf = chat.input_w_buf })
	end
end



---Starting main chat window
---@param uv string: path to uv executable
---@param agent string: path to agent folder
---@param hf_api_key string: hugging face API key
M.start_chat = function(uv, agent, hf_api_key)
	messenger.start_process(uv,
		{ "run", "--directory", agent, "--python", "3.11", vim.fs.joinpath(agent, "main.py"), "hf_api_key=" .. hf_api_key })
	chat_window()
	input_window()
	first_run()

	vim.api.nvim_create_user_command("ChatResponse", reponse, {}
	)
	vim.api.nvim_create_user_command("ChatRefresh", refresh, {}
	)
	vim.api.nvim_create_user_command("ToggleChat", toggle_chat, {}
	)
	vim.api.nvim_create_user_command("CloseChat", close_chat, {})
end


-- M.start_chat()

return M
