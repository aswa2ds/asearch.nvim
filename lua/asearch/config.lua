---@class search_bar_config
---@field popup_options nui_popup_options
---@field default_prompt? string|NuiText

---@class search_menu_config
---@field popup_options nui_popup_options
---@field separator_char string
---@field separator_text_align nui_t_text_align
---@field item_char string
---@field item_text_align nui_t_text_align
---@field max_width integer
---@field keymap nui_menu_keymap

---@class nui_menu_keymap
---@field close string[]
---@field focus_next string[]
---@field focus_prev string[]
---@field submit string[]

---@class search_category
---@field title string
---@field icon string
---@field engines search_engine[]

---@class search_engine
---@field name string
---@field icon string
---@field query_url string
---@field default? boolean
---@field brief string

---@class asearch_config
---@field search_bar  search_bar_config
---@field search_menu  search_menu_config
---@field os_info string
---@field search_engines search_category[]
local config = {
	os_info = require("asearch.utils").get_os_info(),
	search_bar = {
		popup_options = {
			relative = "win",
			size = {
				width = "50%",
			},
			position = {
				row = "80%",
				col = "50%",
			},
			border = {
				style = "rounded",
				text = {
					top = "[A-S-EARCH]",
					top_align = "center",
				},
			},
		},
		default_prompt = "",
	},
	search_menu = {
		popup_options = {
			relative = "win",
			size = {
				width = 20,
			},
			position = {
				row = "80%",
				col = "50%",
			},
			border = {
				style = "rounded",
				text = {
					top = "[A-S-EARCH MENU]",
					top_align = "center",
				},
			},
			win_options = {
				winblend = 10,
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
		},
		separator_char = "=",
		separator_text_align = "center",
		item_char = " ",
		item_text_align = "center",
		keymap = {
			focus_next = { "j", "<Down>", "<Tab>" },
			focus_prev = { "k", "<Up>", "<S-Tab>" },
			close = { "<Esc>", "<C-c>", "<BS>" },
			submit = { "<CR>", "<Space>" },
		},
		max_width = 20,
	},
	search_engines = {
		{
			title = "search",
			icon = "",
			engines = {
				{
					name = "google",
					icon = "",
					query_url = "https://www.google.com/search?q=",
					default = true,
					brief = "gg",
				},
				{
					name = "github",
					icon = "",
					query_url = "https://github.com/search?q=",
					default = false,
					brief = "gt",
				},
			},
		},
	},
}

---get_default_search_engine from config
---@return search_engine
function config:get_default_search_engine()
	for _, category in ipairs(self.search_engines) do
		for _, engine in ipairs(category.engines) do
			if engine.default then
				return engine
			end
		end
	end
	return {
		name = "google",
		icon = "",
		query_url = "https://www.google.com/search?q=",
		default = true,
	}
end

---get search engine by name
---@param name string
---@return search_engine
function config:get_search_engine_by_name(name)
	for _, category in ipairs(self.search_engines) do
		for _, engine in ipairs(category.engines) do
			if engine.name == name then
				return engine
			end
		end
	end
	return {
		name = "google",
		icon = "",
		query_url = "https://www.google.com/search?q=",
		default = true,
	}
end

---get search engine by brief
---@param brief string
---@return search_engine?
function config:get_search_engine_by_brief(brief)
	for _, category in ipairs(self.search_engines) do
		for _, engine in ipairs(category.engines) do
			if engine.brief == brief then
				return engine
			end
		end
	end
end

---get all search engines' briefs
---@return string[]
function config:get_search_engine_briefs()
	---@type string[]
	local briefs = {}
	for _, category in ipairs(self.search_engines) do
		for _, engine in ipairs(category.engines) do
			if engine.brief then
				table.insert(briefs, engine.brief)
			end
		end
	end
	return briefs
end

return config
