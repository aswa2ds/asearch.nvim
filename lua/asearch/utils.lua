local utils = {}
-- Grab OS info on startup
function utils.get_os_info()
	local os = vim.uv.os_uname().sysname:lower()

	if os:find("windows_nt") then
		return "windows"
	elseif os == "darwin" then
		return "mac"
	elseif os == "linux" then
		local f = io.open("/proc/version", "r")
		if f ~= nil then
			local version = f:read("*all")
			f:close()
			if version:find("WSL2") then
				return "wsl2"
			elseif version:find("microsoft") then
				return "wsl"
			end
		end
		return "linux"
	end
end

function utils.os_open_link(os_info, link_location)
	local o = {}
	if os_info == "windows" then
		o.command = "rundll32.exe"
		o.args = { "url.dll,FileProtocolHandler", link_location }
	else
		if os_info == "linux" then
			o.command = "xdg-open"
		elseif os_info == "mac" then
			o.command = "open"
		elseif os_info == "wsl2" then
			o.command = "wslview"
		elseif os_info == "wsl" then
			o.command = "explorer.exe"
		end
		o.args = { link_location }
	end

	require("plenary.job"):new(o):start()
end

function utils.set_search_bar_extmark(namespace_id, extmark_id, virt_text)
	vim.api.nvim_buf_set_extmark(0, namespace_id, 0, 0, {
		id = extmark_id,
		virt_text_pos = "right_align",
		virt_text = virt_text,
	})
end

return utils
