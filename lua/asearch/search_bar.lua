local open = require("asearch.utils").os_open_link
local set_extmark = require("asearch.utils").set_search_bar_extmark
local config = require("asearch.config")
local TopDomain = require("asearch.top_domain")

local Input = require("nui.input")

-- local api = vim.api
--
-- local bnr = vim.fn.bufnr("%")
-- local ns_id = api.nvim_create_namespace("demo")
--
-- local line_num = 11
-- local col_num = 0
--
-- local opts = {
-- 	-- end_line = 10,
-- 	id = 1,
-- 	virt_text = { { "demo", "Normal" } },
-- 	virt_text_pos = "right_align",
-- }
--
-- local mark_id = api.nvim_buf_set_extmark(bnr, ns_id, line_num, col_num, opts)

---@class asearch_bar_internal
---@field type asearch_bar_type
---@field backspace_keymap_exists boolean
---@field tab_keymap_exists boolean
---@field search_engine search_engine
---@field submit_action submit_action
---@field namespace_id integer
---@field rollback fun():nil
---@field search_engine_briefs string[]

---@alias submit_action
---| '"jump"'
---| '"search"'
---| '"change"'

---@alias asearch_bar_type
---| '"raw"'
---| '"search_engine"'
---| '"raw_to_search_engine"'

---@class ASearchBar
---@field private _ asearch_bar_internal
---@field input NuiInput
local SearchBar = {}

function SearchBar:complete_url(value)
	if self._.submit_action == "jump" then
		value = vim.trim(value)
		if vim.startswith(value, "http://") or vim.startswith(value, "https://") then
			return value
		end
		return "https://" .. value
	else
		return self._.search_engine.query_url .. value
	end
end

---@return fun(value: string):nil
function SearchBar:get_on_submit()
	if self._.type == "raw" then
		return function(value)
			if self._.submit_action == "jump" then
				open(config.os_info, self:complete_url(value))
			elseif self._.submit_action == "search" then
				open(config.os_info, self:complete_url(value))
				-- else
				-- 	local search_bar = self:new()
				-- 	local engine = config:get_search_engine_by_brief(value)
				-- 	if engine then
				-- 		search_bar:init({
				-- 			type = "search_engine",
				-- 			prompt = engine.icon,
				-- 			search_engine_name = engine.name,
				-- 			parent = self,
				-- 		})
				-- 		self:unmount()
				-- 		search_bar:mount()
				-- end
			end
		end
	end
	if self._.type == "search_engine" then
		return function(value)
			open(config.os_info, self:complete_url(value))
		end
	end
	return function(_) end
end

---@return fun(value: string):nil
function SearchBar:get_on_change()
	if self._.type == "raw" then
		return function(value)
			if #value == 0 then
				self:map("i", "<BS>", function()
					self:unmount()
				end, { noremap = true })
				self._.backspace_keymap_exists = true
			else
				if self._.backspace_keymap_exists then
					self:unmap("i", "<BS>")
					self._.backspace_keymap_exists = false
				end
			end

			-- local trimed_value = vim.trim(value)
			-- if vim.tbl_contains(self._.search_engine_briefs, trimed_value) then
			-- 	self._.tab_keymap_exists = true
			-- 	self:map("i", "<Tab>", function()
			-- 		self.input.input_props.on_submit(trimed_value)
			-- 	end)
			-- else
			-- 	vim.api.nvim_buf_del_extmark(0, self._.namespace_id, 2)
			-- 	if self._.tab_keymap_exists then
			-- 		self._.tab_keymap_exists = false
			-- 		self:unmap("i", "<Tab>")
			-- 	end
			-- end
			self:change_submit_action(value)
		end
	end
	if self._.type == "search_engine" then
		return function(value)
			if #value == 0 then
				self:map("i", "<BS>", function()
					self._.rollback()
				end, { noremap = true })
				self._.backspace_keymap_exists = true
			else
				if self._.backspace_keymap_exists then
					self:unmap("i", "<BS>")
					self._.backspace_keymap_exists = false
				end
			end
			set_extmark(self._.namespace_id, 1, { { self._.search_engine.name .. " ↵", "ASearch_Search" } })
		end
	end
	return function(_) end
end

---@return fun(): nil
function SearchBar:get_on_close()
	if self._.type == "raw" then
		return function() end
	end
	return function() end
end

function SearchBar:change_submit_action(value)
	value = vim.trim(value)
	if vim.startswith(value, "http://") or vim.startswith(value, "https://") or vim.startswith(value, "www.") then
		self._.submit_action = "jump"
		set_extmark(self._.namespace_id, 1, { { "jump ↵", "ASearch_Jump" } })
		return
	end
	local domain = vim.split(value, "/", { plain = true })[1]
	local split_domain = vim.split(domain, ".", { plain = true })
	local domain_suffix = split_domain[#split_domain]
	if #split_domain ~= 1 and TopDomain:contains(domain_suffix) then
		self._.submit_action = "jump"
		set_extmark(self._.namespace_id, 1, { { "jump ↵", "ASearch_Jump" } })
		return
	end
	-- if self._.tab_keymap_exists then
	-- 	self._.submit_action = "change"
	-- 	set_extmark(
	-- 		self._.namespace_id,
	-- 		2,
	-- 		{ { config:get_search_engine_by_brief(value).name .. " 󰌒 ", "ASearch_Jump" } }
	-- 	)
	-- 	return
	-- end
	self._.submit_action = "search"
	set_extmark(self._.namespace_id, 1, { { self._.search_engine.name .. " ↵", "ASearch_Search" } })
end

---get rollback function for <BS> keymapping calling
---@param parent ASearchBar|ASearchMenu|nil
---@return fun():nil
function SearchBar:get_rollback(parent)
	---@type fun():nil
	local rollback = function()
		self:unmount()
	end
	if parent then
		rollback = function()
			self:unmount()
			parent:mount()
		end
	end
	return rollback
end

---@class asearch_bar_options
---@field type asearch_bar_type
---@field default_value? string
---@field prompt? string
---@field search_engine_name? string
---@field parent? ASearchMenu|ASearchBar

---init function use opts to init SearchBar Instance
---@param opts asearch_bar_options
function SearchBar:init(opts)
	local sb_config = config.search_bar
	self._ = {
		type = opts.type,
		backspace_keymap_exists = false,
		tab_keymap_exists = false,
		search_engine = opts.search_engine_name and config:get_search_engine_by_name(opts.search_engine_name)
			or config:get_default_search_engine(),
		submit_action = "search",
		namespace_id = vim.api.nvim_create_namespace("search_bar"),
		rollback = self:get_rollback(opts.parent),
		search_engine_briefs = config:get_search_engine_briefs(),
	}
	local input = Input(sb_config.popup_options, {
		on_submit = self:get_on_submit(),
		on_close = self:get_on_close(),
		on_change = self:get_on_change(),
		default_value = opts.default_value,
		prompt = " " .. (opts.prompt and opts.prompt or sb_config.default_prompt) .. " ",
	})
	self.input = input
	self:map("n", "<Esc>", function()
		self:unmount()
	end, { noremap = true })
	self:map("i", "<Esc>", function()
		self:unmount()
	end, { noremap = true })
end

function SearchBar:unmount()
	self.input:unmount()
end

function SearchBar:mount()
	self.input:mount()
end

function SearchBar:print()
	for key, value in pairs(self._) do
		print(key, vim.inspect(value))
	end
end

---toggle submit action
---@param value string
function SearchBar:submit(value)
	self.input.input_props.on_submit(value)
end

-- set keymap for this search bar
---@param mode string check `:h :map-modes`
---@param key string|string[] key for the mapping
---@param handler string | fun(): nil handler for the mapping
---@param opts? table<"'expr'"|"'noremap'"|"'nowait'"|"'remap'"|"'script'"|"'silent'"|"'unique'", boolean>
---@return nil
function SearchBar:map(mode, key, handler, opts, __force__)
	self.input:map(mode, key, handler, opts, __force__)
end

---unset keymap for this search bar
---@param mode string check `:h :map-modes`
---@param key string|string[] key for the mapping
---@return nil
function SearchBar:unmap(mode, key, __force__)
	self.input:unmap(mode, key, __force__)
end

function SearchBar:new()
	return setmetatable({}, { __index = self })
end

return SearchBar
