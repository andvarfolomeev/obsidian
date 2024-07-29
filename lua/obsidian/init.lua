local Path = require("plenary.path")

---@class ObsidianState
---@field public vault_dir string|nil

---@class ObsidianOptions
---@field public extra_fd_opts string
---@field public picker picker
-- @field public restore_latest_vault boolean
---@field public vaults ObsidianVaultOptions

---@alias picker
---| '"fzf-lua"'
---| '"telescope"'

---@class ObsidianVaultOptions
---@field public dir string
---@field public daily ObsidianDailyOptions
---@field public templates ObsidianTemplatesOptions
---@field public note ObsidianNoteOptions

---@class ObsidianDailyOptions
---@field public dir string
---@field public format string

---@class ObsidianTemplatesOptions
---@field public dir string
---@field public date string
---@field public time string

---@class ObsidianNoteOptions
---@field public dir string
---@field public transformator function

---@type ObsidianOptions
local default_config = {
	picker = "fzf-lua",
	extra_fd_opts = "",
	-- restore_latest_vault = true,
	vaults = {},
}

local Obsidian = {}
local H = {}

---@type ObsidianOptions
Obsidian.config = {}
---@type ObsidianVaultOptions|nil
Obsidian.current_vault = nil

---@param opts table
---@return nil
Obsidian.setup = function(opts)
	Obsidian.config = vim.tbl_deep_extend("force", default_config, opts)
	Obsidian.config.vaults = vim.tbl_map(
		---@param value ObsidianVaultOptions
		---@return ObsidianVaultOptions
		function(value)
			value.dir = vim.fn.expand(value.dir)
			return value
		end,
		Obsidian.config.vaults
	)
	local state = Obsidian.read_state()
	Obsidian.current_vault = Obsidian.resolve_vault(state)
end

---@param state ObsidianState
---@return ObsidianVaultOptions
Obsidian.resolve_vault = function(state)
	if state.vault_dir ~= nil then
		local vault = vim.tbl_filter(
			---@param vault ObsidianVaultOptions
			---@return boolean
			function(vault)
				return vault.dir == state.vault_dir
			end,
			Obsidian.config.vaults
		)
		if #vault ~= 0 then
			return vault[1]
		end
	end
	return Obsidian.config.vaults[1]
end

---@return ObsidianVaultOptions
Obsidian.get_current_vault = function()
	return Obsidian.current_vault
end

---@return nil
Obsidian.vault_prompt = function()
	vim.ui.select(Obsidian.config.vaults, {
		prompt = "Select vault",
		format_item = function(vault)
			return vault.dir
		end,
	}, function(choise_vault)
		Obsidian.current_vault = choise_vault
		Obsidian.write_state()
	end)
end

---@return nil
Obsidian.cd_vault = function()
	local vault = Obsidian.get_current_vault()
	vim.api.nvim_exec2("cd " .. vault.dir, { output = false })
end

---@param filename string
---@return nil
Obsidian.new_note = function(filename)
	local vault = Obsidian.get_current_vault()
	local transformed_filename = H.resolve_md_extension(vault.note.transformator(filename))
	vim.api.nvim_exec2("edit " .. Path:new({ vault.dir, transformed_filename }):normalize(), { output = false })
end

---@return nil
Obsidian.new_note_prompt = function()
	vim.ui.input({ prompt = "Write name of new note: " }, function(name)
		Obsidian.new_note(name)
	end)
end

---@param shift integer
---@return nil
Obsidian.open_today = function(shift)
	local vault = Obsidian.get_current_vault()
	local time = os.time() + (shift or 0)
	local filename = H.resolve_md_extension(tostring(os.date(vault.daily.format, time)))
	vim.api.nvim_exec2("edit " .. Path:new({ vault.dir, vault.daily.dir, filename }):normalize(), { output = false })
end

---@return nil
Obsidian.open_today_prompt = function()
	vim.ui.input({ prompt = "Write shift in days: " }, function(input_shift)
		local shift = tonumber(input_shift) * 60 * 60 * 24
		Obsidian.open_today(shift)
	end)
end

---@param template_content string
---@param filename string
---@return string
Obsidian.generate_template = function(template_content, filename)
	local vault = Obsidian.get_current_vault()
	local title = filename:gsub("%.md$", "")
	local date = os.date(vault.templates.date)
	local time = os.date(vault.templates.time)
	local result =
		template_content:gsub("{{%s*title%s*}}", title):gsub("{{%s*date%s*}}", date):gsub("{{%s*time%s*}}", time)
	return result
end

---@param template_path string
---@return nil
Obsidian.insert_template = function(template_path)
	---@type string
	local template_content = Path:new(template_path):read() or ""
	local filename = vim.fn.expand("%:t")
	local generated_template = Obsidian.generate_template(template_content, filename)
	vim.api.nvim_paste(generated_template, true, 1)
end

---@return nil
Obsidian.template_picker = function()
	local funcs = {
		["fzf-lua"] = Obsidian.template_picker_fzf_lua,
		["telescope"] = function() end,
	}
	funcs[Obsidian.config.picker]()
end

---@return nil
Obsidian.template_picker_fzf_lua = function()
	local vault = Obsidian.get_current_vault()
	local fzf = require("fzf-lua")
	fzf.files({
		cwd = Path:new({ vault.dir, vault.templates.dir }):normalize(),
		previewer = false,
		file_icons = false,
		winopts = { title = "Templates" },
		actions = {
			default = function(selected)
				if not selected then
					return
				end
				Obsidian.insert_template(Path:new({ vault.dir, vault.templates.dir, selected[1] }):absolute())
			end,
		},
	})
end

---@return nil
Obsidian.note_picker = function()
	local funcs = {
		["fzf-lua"] = Obsidian.note_picker_fzf_lua,
		["telescope"] = function() end,
	}
	funcs[Obsidian.config.picker]()
end

---@return nil
Obsidian.note_picker_fzf_lua = function()
	local vault = Obsidian.get_current_vault()
	local fzf = require("fzf-lua")
	fzf.files({
		cwd = Path:new({ vault.dir }):normalize(),
		previewer = false,
		file_icons = false,
		winopts = { title = "Notes" },
		fd_opts = "--exclude node_modules --exclude .git --exclude .obsidian --exclude templates "
			.. Obsidian.config.extra_fd_opts,
	})
end

---@return nil
Obsidian.backlinks_picker = function()
	local funcs = {
		["fzf-lua"] = Obsidian.backlinks_picker_fzf_lua,
		["telescope"] = function() end,
	}
	funcs[Obsidian.config.picker]()
end

---@return nil
Obsidian.backlinks_picker_fzf_lua = function()
	local vault = Obsidian.get_current_vault()
	local fzf = require("fzf-lua")
	fzf.grep({
		search = H.get_search_string_for_backlinks(),
		no_esc = true,
		cwd = Path:new({ vault.dir }):normalize(),
		previewer = false,
		file_icons = false,
		winopts = { title = "Backlinks" },
		rg_opts = "--glob !node_modules --glob !.git --glob !*.log",
	})
end

---@return number|nil, number|nil, string|nil
Obsidian.found_wikilink_under_cursor = function()
	local line = vim.api.nvim_get_current_line()
	local column = vim.api.nvim_win_get_cursor(0)[2] + 1
	local pattern = "%[%[([^|%]]+)|?[^%]]*%]%]"
	local open_pos, close_pos, filename = string.find(line, pattern)
	while open_pos do
		if open_pos <= column and column <= close_pos then
			return open_pos, close_pos, filename
		end
		open_pos, close_pos, filename = string.find(line, pattern, close_pos + 1)
	end
	return nil, nil, nil
end

---@return nil
Obsidian.go_to = function()
	local _, _, filename = Obsidian.found_wikilink_under_cursor()
	if filename == nil then
		H.notify("It's not wiki link", vim.log.levels.ERROR)
		return
	end
	local vault = Obsidian.get_current_vault()
	local matches = H.search_file(vault.dir, vim.fn.shellescape("/" .. filename .. ".md"))
	if #matches == 0 then
		local dir_path = vim.fn.expand("%:p:h")
		local target_file = dir_path .. "/" .. H.resolve_md_extension(filename)
		vim.api.nvim_command("edit " .. target_file)
		H.notify("New file created")
		return
	end
	if #matches == 1 then
		vim.api.nvim_command("edit " .. matches[1])
		return
	end
	vim.ui.select(matches, {
		prompt = "Select file: ",
	}, function(match)
		vim.api.nvim_command("edit " .. match)
	end)
end

---@param new_name string
Obsidian.rename = function(new_name)
	local vault = Obsidian.get_current_vault()
	local filepath = vim.fn.expand("%:p")
	local buffer_id = vim.api.nvim_get_current_buf()
	local new_filepath = H.resolve_md_extension(Path:new({ vim.fn.expand("%:p:h"), new_name }):absolute())
	if filepath == new_filepath then
		return
	end
	if not Obsidian.is_current_vault_note() then
		vim.notify(new_filepath .. " is not vault note", vim.log.levels.ERROR)
		return
	end
	if Path:new(new_filepath):exists() then
		vim.notify(new_filepath .. " already exists", vim.log.levels.ERROR)
		return
	end
	vim.loop.fs_rename(filepath, new_filepath)
	local old = { [[\[\[]], vim.fn.expand("%:t:r"), "(\\|[^\\]\\[]+)?\\]\\]" }
	local new = { "[[", new_name:gsub("%.md$", ""), "$1]]" }
	H.replace_in_dir(vault.dir, table.concat(old, ""), table.concat(new, ""))
	vim.api.nvim_buf_delete(buffer_id, { force = true })
	vim.api.nvim_command("edit " .. new_filepath)
end

---@return nil
Obsidian.rename_prompt = function()
	vim.ui.input({ prompt = "New name: " }, function(name)
		Obsidian.rename(name)
	end)
end

---@return boolean
Obsidian.is_current_vault_note = function()
	local vault = Obsidian.get_current_vault()
	local current_file_path = vim.fn.expand("%:p")
	return current_file_path:match("^" .. Path:new(vault.dir):absolute())
end

---@type Path
Obsidian.state_file = Path:new(vim.fn.stdpath("state"), "obsidian.json")

---@return nil
Obsidian.write_state = function()
	local state = { vault_dir = Obsidian.current_vault.dir }
	local encoded_state = vim.json.encode(state)
	Obsidian.state_file:write(encoded_state, "w")
end

---@return ObsidianState
Obsidian.read_state = function()
	if not Obsidian.state_file:exists() then
		return {}
	end
	---@type string
	---@diagnostic disable-next-line: assign-type-mismatch
	local encoded_state = Obsidian.state_file:read()
	local state = vim.json.decode(encoded_state)
	return state
end

--- @return table
Obsidian.get_cmp_source = function()
	local source = {}

	source.new = function()
		return setmetatable({}, { __index = source })
	end

	source.complete = function(_, params, callback)
		local before_line = params.context.cursor_before_line
		if not string.find(string.reverse(before_line), "[[", 1, true) then
			callback({ items = {}, isIncomplete = false })
			return
		end
		local files = H.get_list_of_files(Obsidian.get_current_vault().dir)
		local items = vim.tbl_map(function(file)
			local splitted_path = vim.split(file, "/")
			local filename = splitted_path[#splitted_path]:gsub(".md", "")
			return { kind = 17, label = file, insertText = filename }
		end, files)

		callback({ items = items, isIncomplete = false })
	end

	source.get_trigger_characters = function()
		return { "[" }
	end

	source.is_available = function()
		local file_dir = vim.fn.expand("%:p")
		local vault = Obsidian.get_current_vault()
		if vault == nil then
			return false
		end
		return string.find(file_dir, vault.dir, 1, true) == 1
	end

	return source
end

---@param filename string
---@return string
H.resolve_md_extension = function(filename)
	if string.find(filename:lower(), "%.md$") then
		return filename
	end
	return filename .. ".md"
end

---@return string
H.get_search_string_for_backlinks = function()
	local filename = vim.fn.expand("%:t"):gsub("%.md$", "")
	return [[\[\[]] .. filename .. [[\|.*\]\]|\[\[]] .. filename .. "]]"
end

---@param cmd string|table
---@return file*
H.execute_os_cmd = function(cmd)
	if type(cmd) == "table" then
		return assert(io.popen(table.concat(cmd, " "), "r"))
	end
	return assert(io.popen(cmd, "r"))
end

H.get_list_of_files = function(dir)
	local cmd = { "rg", "--files", dir, "--glob '*.md'" }
	local result = {}
	local command_result = H.execute_os_cmd(cmd)
	for line in command_result:lines() do
		result[#result + 1] = line
	end
	return result
end

---@param dir string
---@param filename string
H.search_file = function(dir, filename)
	local cmd = { "fd", "--full-path", "--search-path", dir, "|", "rg", filename }
	local result = {}
	local command_result = H.execute_os_cmd(cmd)
	for line in command_result:lines() do
		result[#result + 1] = line
	end
	return result
end

---@param dir string
---@param old string
---@param new string
---@return nil
H.replace_in_dir = function(dir, old, new)
	local cmd = { "fd", "--full-path", dir, "--type", "file", "--exec", "sd", "'" .. old .. "'", "'" .. new .. "'" }
	H.execute_os_cmd(table.concat(cmd, " "))
end

---@param msg string
---@param level integer|nil
---@param opts table|nil
H.notify = function(msg, level, opts)
	vim.notify(msg, level or vim.log.levels.INFO, vim.tbl_deep_extend("force", { title = "Obsidian" }, opts or {}))
end

return Obsidian
