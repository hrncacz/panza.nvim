local M = {}

local chat = {
	chat_w_win = nil,
	chat_w_buf = nil,
	input_w_win = nil,
	input_w_buf = nil,
	messages = {}
}

local function create_window_config(opts)
	local opts = opts or {}
	local width = vim.o.columns
	local height = vim.o.lines
	local chat_w_width = math.floor(width * 0.4)
	local chat_w_height = math.floor(height * 0.9) - 10
	local chat_w_columns = width - chat_w_width
	local chat_w_rows = math.floor((height - chat_w_height) / 2 - 5)

	return {
		chat = {
			relative = "editor",
			width = chat_w_width,
			height = chat_w_height,
			col = chat_w_columns,
			row = chat_w_rows,
			style = "minimal",
			border = "rounded"
		},
		input = {
			relative = "editor",
			width = chat_w_width,
			height = 5,
			col = chat_w_columns,
			row = chat_w_height + 5,
			style = "minimal",
			border = "rounded",
			title = "Enter your prompt",
			title_pos = "center"
		},
	}
end


local function open_float(opts)
	opts = opts or {}
	-- Defaults
	print(opts.win_cfg.relative)
	-- Create a new scratch buffer
	local buf = nil
	if vim.api.nvim_buf_is_valid(opts.buf) then
		buf = opts.buf
	else
		buf = vim.api.nvim_create_buf(false, true)
	end

	-- Open floating window
	local win = vim.api.nvim_open_win(buf, true, opts.win_cfg)

	return buf, win
end

---Starting main chat window
M.chat_window = function()
	local chat_config = create_window_config().chat
	chat.chat_w_buf, chat.chat_w_win = open_float({ buf = -1, win_cfg = chat_config })
	local input_config = create_window_config().input
	chat.input_w_buf, chat.input_w_win = open_float({ buf = -1, win_cfg = input_config })
end

---Appending new message to chat window
---@param message panza.Message
M.append_message = function(message)

end

M.chat_window()

return M
