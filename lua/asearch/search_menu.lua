local config = require("asearch.config")
local is_type = require("nui.utils").is_type
local defaults = require("nui.utils").defaults
local _ = require("nui.utils")._
local Menu = require("nui.menu")
local Text = require("nui.text")
local Line = require("nui.line")

---@class asearch_menu_internal
---@field default_value string

---@class ASearchMenu
---@field private _ asearch_menu_internal
---@field menu NuiMenu
local SearchMenu = {}

function SearchMenu:get_prepare_item()
	local sm_config = config.search_menu

	local max_width = sm_config.max_width
	local function default_prepare_node(node)
		local content = is_type("string", node.text) and Text(node.text) or node.text

		if node._type == "item" then
			local fill_char = Text(defaults(node._char, " "))
			local fill_text_align = defaults(node._text_align, "center")

			local fill_max_width = max_width - fill_char:width() * 2

			if content:width() > max_width then
				if is_type("function", content.set) then
					_.truncate_nui_text(content, max_width)
				else
					_.truncate_nui_line(content, max_width)
				end
			end

			local left_gap_width, right_gap_width =
				_.calculate_gap_width(defaults(fill_text_align, "center"), fill_max_width, content:width())

			local line = Line()

			line:append(Text(fill_char))

			if left_gap_width > 0 then
				line:append(Text(fill_char):set(string.rep(fill_char:content(), left_gap_width)))
			end

			line:append(content)
			--
			if right_gap_width > 0 then
				line:append(Text(fill_char):set(string.rep(fill_char:content(), right_gap_width)))
			end

			line:append(Text(fill_char))

			return line
		end

		if node._type == "separator" then
			local sep_char = Text(defaults(node._char, "="))
			local sep_text_align = defaults(node._text_align, "center")

			local sep_max_width = max_width - sep_char:width() * 2

			if content:width() > sep_max_width then
				if content._texts then
					_.truncate_nui_line(content, sep_max_width)
				else
					_.truncate_nui_text(content, sep_max_width)
				end
			end

			local left_gap_width, right_gap_width =
				_.calculate_gap_width(defaults(sep_text_align, "center"), sep_max_width, content:width())

			local line = Line()

			line:append(Text(sep_char))

			if left_gap_width > 0 then
				line:append(Text(sep_char):set(string.rep(sep_char:content(), left_gap_width)))
			end

			line:append(content)

			if right_gap_width > 0 then
				line:append(Text(sep_char):set(string.rep(sep_char:content(), right_gap_width)))
			end

			line:append(Text(sep_char))

			return line
		end
	end
	return default_prepare_node
end

---@return NuiTree.Node[]
function SearchMenu:build_nui_menu_lines()
	local sm_config = config.search_menu
	local se_config = config.search_engines
	local lines = {}

	for _, category in ipairs(se_config) do
		if category.title then
			local separator_icon = category.icon and category.icon .. " " or ""
			local separator_text = " " .. separator_icon .. string.upper(category.title) .. " "
			local separator = Menu.separator(separator_text, {
				char = sm_config.separator_char and sm_config.separator_char or "=",
				text_align = sm_config.separator_text_align and sm_config.separator_text_align or "center",
			})
			table.insert(lines, separator)
		end
		for _, engine in ipairs(category.engines) do
			local item_icon = engine.icon and engine.icon .. " " or ""
			local item_text = item_icon .. string.upper(engine.name)
			local item_data = {
				_icon = item_icon,
				_name = engine.name,
				_brief = engine.brief,
				_query_url = engine.query_url,
				_char = sm_config.item_char and sm_config.item_char or " ",
				_text_align = sm_config.item_text_align and sm_config.item_text_align or "center",
			}
			local line = Menu.item(item_text, item_data)
			-- P(item.data)
			table.insert(lines, line)
		end
	end
	return lines
end

---@return fun(item: NuiTree.Node): nil
function SearchMenu:get_on_submit()
	return function(item)
		-- print(item.text, item._icon, item._char, item._text_align, item._query_url)
		local search_bar = require("asearch.search_bar"):new()
		search_bar:init({
			default_value = self._.default_value,
			type = "search_engine",
			prompt = item._icon,
			search_engine_name = item._name,
			parent = self,
		})
		search_bar:mount()
	end
end

---@class asearch_menu_options
---@field default_value string

---init function use opts to init SearchBar Instance
---@param opts asearch_menu_options
function SearchMenu:init(opts)
	local sm_config = config.search_menu
	self._ = {
		default_value = opts.default_value,
	}
	local menu = Menu(sm_config.popup_options, {
		keymap = sm_config.keymap,
		lines = self:build_nui_menu_lines(),
		prepare_item = self:get_prepare_item(),
		max_width = sm_config.max_width,
		on_submit = self:get_on_submit(),
	})
	self.menu = menu
end

function SearchMenu:unmount()
	self.menu:unmount()
end

function SearchMenu:mount()
	self.menu:mount()
end

function SearchMenu:new()
	return setmetatable({}, { __index = self })
end

return SearchMenu
