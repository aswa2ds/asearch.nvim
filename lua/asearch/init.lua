local asearch = {}

---setup function use opts setup asearch plugin's configuration
---@param opts any
function asearch.setup(opts)
	opts = opts or {}
	vim.api.nvim_set_hl(0, "ASearch_Search", {
		fg = "#89b4fa",
	})
	vim.api.nvim_set_hl(0, "ASearch_Jump", {
		fg = "#f8bd96",
	})
	local sm_config = require("asearch.config").search_menu
	sm_config.popup_options.size.width = sm_config.max_width
end

function asearch.toggle_raw_search_bar()
	local search_bar = require("asearch.search_bar"):new()

	vim.fn.setreg("v", {})
	vim.api.nvim_command('noa normal! "vy')
	local selected_text = vim.fn.getreg("v")
	vim.fn.setreg("v", {})

	search_bar:init({
		type = "raw",
		default_value = type(selected_text) == "string" and selected_text or "",
	})

	search_bar:mount()
end

function asearch.toggle_search_menu()
	local search_menu = require("asearch.search_menu"):new()

	vim.fn.setreg("v", {})
	vim.api.nvim_command('noa normal! "vy')
	local selected_text = vim.fn.getreg("v")
	vim.fn.setreg("v", {})

	search_menu:init({
		default_value = type(selected_text) == "string" and selected_text or "",
	})

	search_menu:mount()
end

return asearch
