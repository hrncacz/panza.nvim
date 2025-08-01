<div align="center">

# PANZA.NVIM


### Description

- AI Chat assistant
- Runnig [OpenHermes][https://huggingface.co/teknium/OpenHermes-2.5-Mistral-7B] LLM
- Quick help for beginners.


### Requirements

- Python3
- HuggingFace API token - READ rights


### Instalation

```lua
Plug 'hrncacz/panza.nvim'

```

### Configuration

```lua
require("panza").load_module({ hf_api_key = "YOUR HUGGING FACE API KEY" })
```

### Keymaps

- There is currently only one keymap, `N` mode `<CR>` inside input window of chat will trigger `:SendMessage` command
```lua
vim.keymap.set("n", "<CR>", ":SendMessage<CR>", {})
```


### Commands

- `:OpenChat`
    - Opening chat and input window
    - Starting python AI agent process
    - First run may take a while, because all model files must be downloaded
- `:ToggleChat`
    - Closes / Open chat and input window
    - Process keeps running in background
    - Opening is instantetuous
- `:CloseChat`
    - Closes chat and input window
    - Kills AI agent process
- `:SendMessage`
    - Converts all lines of input window a sends them to AI agent
- `:ChatResponse`
    - Triggers refresh of chat window


### ToDo

- [ ] Coloring of chat messages based on role
- [ ] Adding health check
- [ ] More informative messages about loading of AI Agent
- [ ] Possibility of LLM model selection in config
- [ ] Persistent chat messages per project
- [ ] Adding tools to AI agent



