local chat = {
	messages = {},
	msg_buf = nil,
	msg_win = nil,
	input_buf = nil,
	input_win = nil,
}

-- 🪟  Create the message window (top half)
local function create_message_window()
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.6)

	chat.msg_buf = vim.api.nvim_create_buf(false, true)
	chat.msg_win = vim.api.nvim_open_win(chat.msg_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = 2,
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
	})

	vim.api.nvim_buf_set_option(chat.msg_buf, "modifiable", false)
end

-- ⌨️ Create input window (bottom line)
local function create_input_window()
	chat.input_buf = vim.api.nvim_create_buf(false, true)

	local width = math.floor(vim.o.columns * 0.8)
	local row = math.floor(vim.o.lines * 0.6) + 3

	chat.input_win = vim.api.nvim_open_win(chat.input_buf, true, {
		relative = "editor",
		width = width,
		height = 1,
		row = row,
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "single",
	})

	vim.keymap.set("i", "<CR>", function()
		local lines = vim.api.nvim_buf_get_lines(chat.input_buf, 0, -1, false)
		local input = table.concat(lines, "\n")
		vim.api.nvim_buf_set_lines(chat.input_buf, 0, -1, false, {})

		if input == "exit" then
			chat.close()
			return
		end

		table.insert(chat.messages, { role = "user", content = input })
		table.insert(chat.messages, { role = "assistant", content = "Echo: " .. input })

		chat.refresh()
	end, { buffer = chat.input_buf })
end

-- 🔁 Refresh message window with new messages
function chat.refresh()
	vim.api.nvim_buf_set_option(chat.msg_buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(chat.msg_buf, 0, -1, false, {})
	for _, msg in ipairs(chat.messages) do
		local prefix = msg.role == "user" and "You: " or "AI: "
		vim.api.nvim_buf_set_lines(chat.msg_buf, -1, -1, false, { prefix .. msg.content })
	end
	vim.api.nvim_buf_set_option(chat.msg_buf, "modifiable", false)
end

-- 🧹 Close all
function chat.close()
	if chat.msg_win then vim.api.nvim_win_close(chat.msg_win, true) end
	if chat.input_win then vim.api.nvim_win_close(chat.input_win, true) end
end

-- 🚀 Launch the chat UI
function chat.open()
	create_message_window()
	create_input_window()
	vim.cmd("startinsert")
end

chat.open()

return chat
