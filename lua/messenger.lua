local M = {}

---@class panza.Message
---@field role string: AI model role as assistant, user, tool
---@field content string: content of a message


local chat_proc = {
	handle = nil, -- handle for communication with process
	stdin = nil, -- input stream
	stdout = nil, -- output stream
	chat = {},   -- buffre for messages acumulation
	ready = false -- state of process
}

local function set_chat_proc_default()
	chat_proc.handle = nil
	chat_proc.stdin = nil
	chat_proc.stdout = nil
	chat_proc.chat = {}
	chat_proc.ready = false
end

---@param exec string: Executable to be run
---@param args string[]: Arguments
M.start_process = function(exec, args)
	if exec == nil or args == nil then
		print("main_loop fucntion call is missing parameters")
		return
	end
	if chat_proc.handle then
		print("Chat is already running")
		return
	end
	local stdin = vim.uv.new_pipe()
	local stdout = vim.uv.new_pipe()
	local close_chat

	local handle, pid = vim.uv.spawn(exec, {
		args = args,
		stdio = { stdin, stdout, nil }
	}, close_chat)

	close_chat = function(code, signal)
		stdin:close()
		stdout:close()
		handle:close()
		set_chat_proc_default()
		print("Chat process ended with code: ", code)
	end

	stdout:read_start(function(err, data)
		assert(not err, err)
		if data then
			vim.schedule(function()
				table.insert(chat_proc.chat, { role = "assistant", content = data })
				vim.api.nvim_command("ChatResponse")
			end)
		end
	end)
	chat_proc.handle = handle
	chat_proc.stdin = stdin
	chat_proc.stdout = stdout
	chat_proc.ready = true

	print("Process has successfully started with PID: ", pid)
end

M.close_process = function()
	print("You have called close_process")
	if chat_proc.handle then
		chat_proc.handle:kill("sigterm")
		set_chat_proc_default()
		return
	end
end

M.send_message = function(user_input)
	if not chat_proc.ready then
		print("Chat process is not running")
		return
	end
	table.insert(chat_proc.chat, { role = "user", content = user_input })
	local status, result = pcall(vim.json.encode, chat_proc.chat)
	if not status then
		print("Error decoding json: " .. result)
	else
		print(result)
		vim.loop.write(chat_proc.stdin, result .. "\n")
		vim.api.nvim_command("ChatRefresh")
	end
end

M.get_all_messages = function()
	return chat_proc.chat
end


return M
