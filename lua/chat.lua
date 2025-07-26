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
	chat_proc.buffer = ""
	chat_proc.ready = false
end

---@param exec string: Executable to be run
---@param args string[]: Arguments
local function start_chat(exec, args)
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
			table.insert(chat_proc.chat, { role = "assistant", content = data })
			vim.schedule(function()
				print("Response: ", vim.trim(data))
			end)
		end
	end)
	chat_proc.handle = handle
	chat_proc.stdin = stdin
	chat_proc.stdout = stdout
	chat_proc.ready = true

	print("Process has successfully started with PID: ", pid)
end

local function close_process()
	print("You have called close_process")
	if chat_proc.handle then
		chat_proc.handle:kill("sigterm")
		set_chat_proc_default()
		return
	end
end

local function send_message(user_input)
	if not chat_proc.ready then
		print("Chat process is not running")
		return
	end
	table.insert(chat_proc.chat, { role = "user", content = user_input })
	local status, result = pcall(vim.json.encode, chat_proc.chat)
	if not status then
		print("Error decoding json: " .. result)
	else
		print("JSON: ", result)
		vim.loop.write(chat_proc.stdin, result .. "\n")
	end
end

local function chat_loop()
	for key, value in pairs(chat_proc.chat) do
		print("Printing full chat:")
		print("Text round:", key)
		print("Content", value.content)
	end

	vim.ui.input({ prompt = "Enter your message: " }, function(input)
		if vim.trim(string.lower(input)) == "exit" then
			close_process()
		elseif input == "" or input == nil then
			chat_loop()
		else
			send_message(input)
			chat_loop()
		end
	end)
end

---comment
---@param exec string: Executable to be run
---@param args string[]: Arguments
M.main_loop = function(exec, args)
	if exec == nil or args == nil then
		print("main_loop fucntion call is missing parameters")
		return
	end
	start_chat(exec, args)

	-- start chat loop
	chat_loop()
end

return M
