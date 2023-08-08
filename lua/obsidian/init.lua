--- *obsidian* provide base Obsidian functionality to your Neovim
--- *Obsidian*
---
--- MIT License Copyright (c) 2023 Andrey Varfolomeev
---
--- ==============================================================================
---
--- That aimed to provide base Obsidian functionality to Neovim, but stay
--- stupid simple.
---
--- # Features ~
---
--- - Opening vault
---
--- - Creating new notes
---
--- - Creating/Opening daily notes
---
--- - Selecting and inserting templates to buffer with support placeholders
---   like: ``{{title}}``, ``{{date}}``, ``{time}}``
---
--- - Searching notes with Telescope integration
---
--- - Searching backlinks of current note
---
--- # Setup ~
---
--- This module needs a setup with `require('obsidian').setup({})` (replace
--- `{}` with your `config` table). It will create global Lua table `Obsidian`
--- which you can use for scripting or manually (with `:lua Obsidian.*`).
---
--- See |Obsidian.config| for available config settings.
---
--- Structure of project inpired by echasnovski/mini.nvim

---@diagnostic disable:undefined-field
---@diagnostic disable:discard-returns
---@diagnostic disable:unused-local
---@diagnostic disable:cast-local-type

---@alias __obsidian_select_method string - one of selection method. It can equal 'native' or 'telescope'

-- Module definition ==========================================================
local Obsidian = {}
local H = {}

local default_config = {}

---@param opts table|nil Module config table. See |Obsidian.config|.
---
---@usage `require('Obsidian').setup({})` (replace `{}` with your `config` table)
Obsidian.setup = function(opts)
  _G.Obsidian = Obsidian
  config = H.setup_config(opts)
  H.apply_config(config)
  H.create_autocommands(config)
  H.create_default_hl()
end

--stylua: ignore
--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)

Obsidian.config = {
  -- Optional, the path to vault directory
  dir = '~/ObsidianVault/',

  daily = {
    -- Optional, the path to daily notes directory
    dir = 'daily/',      -- Optional, It is mean that daily note directory is ~/ObsidianVault/daily/
    format = '%Y-%m-%d', -- Optional, format file names
  },
  templates = {
    -- Optional, the path to templates directory
    dir = 'templates/',
    date = '%Y-%d-%m',
    time = '%Y-%d-%m',
  },
  note = {
    -- Optional, the path to general notes directory
    dir = 'notes/',
    -- Optional, the function for fransform name of note
    ---@param filename string
    ---@return string
    transformator = function(filename)
      if filename ~= nil and filename ~= '' then
        return filename
      end
      return string.format('%d', os.time())
    end,
  },
}
--minidoc_afterlines_end

--- Open vault directory
---
---  Common way to use this function:
---
--- - `Obsidian.cd_vault()` - open directory - This moves your working directory to the vault.
Obsidian.cd_vault = function()
  vim.api.nvim_command('cd ' .. Obsidian.config.dir)
end

--- Create new note
---
--- Common ways to use this function:
---
--- - `Obsidian.new_note('new-note')` - create note in |Obsidian.config.note.dir|.
---
--- - `Obsidian.new_note('new-note.md')` - create note in |Obsidian.config.note.dir|.
---
--- - `vim.ui.input({ prompt = 'Write name of new note: ' }, function(name)`
---   `  Obsidian.new_note(name)`
---   `end)` - create note in |Obsidian.config.note.dir|.
---@param filename string
Obsidian.new_note = function(filename)
  local filepath = H.prepare_path(
    Obsidian.config.note.transformator(filename),
    Obsidian.config.note.dir,
    true
  )
  vim.api.nvim_command('edit ' .. filepath)
end

--- Open today note
---
--- Common ways to use this function:
---
--- - `Obsidian.open_today()` - open today note in |Obsidian.config.daily.dir|
---   with |Obsidian.cofnig.daily.format| format.
---
--- - `vim.ui.input({ prompt = 'Write name of new note: ' }, function(name)`
---      `Obsidian.new_note(name)`
---   `end)` - also you can use it to open daily note with some time shift.
---@param shift integer
Obsidian.open_today = function(shift)
  local time = os.time() + (shift or 0)
  local filepath = H.prepare_path(
    tostring(os.date(Obsidian.config.daily.format, time)),
    Obsidian.config.daily.dir,
    true
  )
  vim.api.nvim_command('edit ' .. filepath)
end

--- Generate template
---
--- Generates text from the template body to be inserted into the note
---@param template_content string
---@param filename string
---@return string
Obsidian.generate_template = function(template_content, filename)
  local title_ = filename:gsub('%.md$', '')
  local date = os.date(Obsidian.config.templates.date)
  local time = os.date(Obsidian.config.templates.time)
  local result = template_content
      :gsub('{{%s*title%s*}}', title_)
      :gsub('{{%s*date%s*}}', date)
      :gsub('{{%s*time%s*}}', time)
  return result
end

--- Insert template to current buffer
---
---@param template_path string
Obsidian.insert_template = function(template_path)
  local processed_template =
      Obsidian.generate_template(H.read_file(template_path), vim.fn.expand('%:t'))
  vim.api.nvim_paste(processed_template, true, 1)
end

--- Select template
---
--- Common ways to use this function:
---
--- - `Obsidian.select_template()`- This brings up a vim.ui.select for selecting a
---   template for later pasting into current buffer.
---
--- - `Obsidian.select_template('native')` - This brings up a vim.ui.select for selecting a
---   template for later pasting into current buffer.
---
--- - `Obsidian.select_template('telescope')`- This brings up a telescope for selecting a
---   template for later pasting into current buffer.
---@param method_str __obsidian_select_method
Obsidian.select_template = function(method_str)
  local methods = {
    native = Obsidian.select_template_native,
    telescope = Obsidian.select_template_telescope,
  }
  local method = methods[method_str]
  local callback = Obsidian.insert_template
  if method then
    method(callback)
  else
    methods.native(callback)
  end
end

---@param callback function
Obsidian.select_template_native = function(callback)
  local template_files =
      vim.fn.glob(Obsidian.config.dir .. Obsidian.config.templates.dir .. '*', false, true)
  vim.ui.select(template_files, {
    prompt = 'Select template: ',
  }, callback)
end

---@param callback function
Obsidian.select_template_telescope = function(callback)
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local find_files = require('telescope.builtin').find_files
  find_files({
    prompt_title = 'Templates',
    cwd = Obsidian.config.dir .. Obsidian.config.templates.dir,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        callback(Obsidian.config.dir .. Obsidian.config.templates.dir .. selection[1])
      end)
      return true
    end,
  })
end

--- Search note
---
--- Common ways to use this function:
---
--- - `Obsidian.search_note()` - This brings up a telescope for search a
---   notes in |Obsidian.config.dir|
Obsidian.search_note = function()
  local find_files = require('telescope.builtin').find_files
  find_files({
    prompt_title = 'Select note',
    cwd = Obsidian.config.dir,
  })
end

--- Select backlinks
---
--- Common ways to use this function:
---
--- - `Obsidian.select_backlinks()` - This brings up a vim.ui.select for search a
---   backlinks for current note.
---
--- - `Obsidian.select_backlinks('native')` - This brings up a vim.ui.select for search a
---   backlinks for current note.
---
--- - `Obsidian.select_backlinks('telescope')` - This brings up a telescope for search a
---   backlinks for current note.
---@param method_str __obsidian_select_method
Obsidian.select_backlinks = function(method_str)
  local methods = {
    native = Obsidian.select_backlinks_native,
    telescope = Obsidian.select_backlinks_telescope,
  }
  local method = methods[method_str]
  if method then
    method()
  else
    methods.native()
  end
end

Obsidian.select_backlinks_native = function()
  local filename = vim.fn.expand('%:t'):gsub('%.md$', '')
  local query = '[[' .. filename
  local search_result = H.search_rg(query)
  vim.ui.select(search_result, {
    prompt = "Go to",
    format_item = function(match)
      return match.path
    end
  }, function(match)
    vim.api.nvim_command('edit ' .. match.path)
    vim.fn.cursor(match.cursor)
  end)
end

Obsidian.select_backlinks_telescope = function()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local entry_display = require("telescope.pickers.entry_display")
  local filename = vim.fn.expand('%:t'):gsub('%.md$', '')
  local query = '[[' .. filename
  local search_result = H.search_rg(query)

  local displayer = entry_display.create({
    separator = " ",
    items = { { width = 80, }, { remaining = true } },
  })

  local opts = {}

  pickers.new(opts, {
    prompt_title = "Backlinks",
    finder = finders.new_table {
      results = search_result,
      entry_maker = function(match)
        local path = string.gsub(match.path, vim.fn.expand(Obsidian.config.dir), '')
        return {
          value = match,
          display = match.path,
          ordinal = path,
          path = path,
        }
      end
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local match = selection.value;
        vim.api.nvim_command('edit ' .. match.path)
        vim.fn.cursor(match.cursor)
      end)
      return true
    end,
    sorter = conf.generic_sorter(opts)
  })
      :find()
end

Obsidian.found_wikilink_under_cursor = function()
  local line = vim.api.nvim_get_current_line()
  local column = vim.api.nvim_win_get_cursor(0)[2] + 1
  local pattern = "%[%[([^|%]]+)|?[^%]]*%]%]"
  local open, close, filename = string.find(line, pattern)
  while open do
    if open <= column and column <= close then
      return open, close, filename
    end
    open, close, filename = string.find(line, pattern, close + 1)
  end
  return nil, nil, nil
end

---Go to note by wiki link under cursor
---
--- Common ways to use this function:
---
--- - `Obsidian.got_to()`
---
--- It calls edit for file if file with it name only one.
---
--- It calls vim.ui.select if file with it name few. However, It calls edit for file
--- too after selection.
Obsidian.go_to = function()
  local _, _, filename = Obsidian.found_wikilink_under_cursor()
  if filename == nil then
    print('It is not wikilink')
    return
  end
  local matches = H.search_file(filename)
  if #matches == 0 then
    local dir_path = vim.fn.expand("%:p:h")
    local target_file = dir_path .. "/" .. H.resolve_md_extension(filename)
    vim.api.nvim_command('edit ' .. target_file)
    print('New file created')
    return
  end
  if #matches == 1 then
    vim.api.nvim_command('edit ' .. matches[1])
    return
  end
  vim.ui.select(matches, {
    prompt = 'Select file: ',
  }, function(match)
    vim.api.nvim_command('edit ' .. match)
  end)
end

--- Rename current file with updating links
---
--- Common ways to use this function:
---
--- - `Obsidian.rename('new-note')`
---
--- - `vim.ui.input({ prompt = 'Rename file to' }, function(name)`
---   `  Obsidian.rename(name)`
---   `end)`
---@param filename string
Obsidian.rename = function(new_name)
  local filepath = vim.fn.expand("%:p")
  local new_file = H.resolve_md_extension(vim.fn.expand("%:p:h") .. "/" .. new_name)
  vim.loop.fs_rename(filepath, new_file)
  H.replace_in_vault('[[' .. vim.fn.expand('%:t:r') .. ']]', '[[' .. new_name .. ']]')
  vim.api.nvim_command('edit ' .. new_file)
end

--- Cmp source
---
--- Common ways to use this function:
---
--- - `require('cmp').register_source('obsidian', require('obsidian').get_cmp_source().new())`
---@return table
Obsidian.get_cmp_source = function()
  local source = {}

  source.new = function()
    return setmetatable({}, { __index = source })
  end

  source.complete = function(self, params, callback)
    local before_line = params.context.cursor_before_line
    if not string.find(string.reverse(before_line), "[[", 1, true) then
      callback {
        items = {},
        isIncomplete = false,
      }
      return
    end
    local files = H.get_list_of_files(Obsidian.config.dir)
    local items = vim.tbl_map(function(file)
      local splitted_path = vim.split(file, "/")
      local filename = splitted_path[#splitted_path]:gsub(".md", "")
      return {
        kind = 17,
        label = file,
        insertText = filename,
      }
    end, files)

    callback {
      items = items,
      isIncomplete = false,
    }
  end

  source.get_trigger_characters = function()
    return { "[" }
  end

  source.is_available = function()
    local vault_dir = vim.fn.expand(Obsidian.config.dir)
    local file_dir = vim.fn.expand("%:p")
    return string.find(file_dir, vault_dir, 1, true) == 1
  end

  return source
end

-- Helper functionality =======================================================

---Validating user configuration that it is correct
---@param opts table|nil
---@return table|nil
H.setup_config = function(opts)
  return opts
end

---Apply user configuration
---@param opts table|nil
H.apply_config = function(opts)
  Obsidian.config = vim.tbl_deep_extend('force', Obsidian.config, opts)
end

---@param opts table|nil
H.create_autocommands = function(opts) end

---@param opts table|nil
H.create_default_hl = function(opts) end

---@param path string
---@return boolean
H.directory_exist = function(path)
  return vim.fn.isdirectory(path) == 1
end

---@param path string
H.create_dir_force = function(path)
  vim.fn.mkdir(path, 'p')
end

---That add markdown extension to end of file and create subdirectory
---if it is settled and not already created
---@param filename string
---@param subdir string
---@param create_dir boolean
---@return string
H.prepare_path = function(filename, subdir, create_dir)
  local processed_filename = H.resolve_md_extension(filename)
  local dir = Obsidian.config.dir .. subdir
  if create_dir and not H.directory_exist(dir) then
    H.create_dir_force(vim.fn.expand(dir))
  end
  local filepath = Obsidian.config.dir .. subdir .. processed_filename
  return filepath
end

---That add markdown extension to end of file
---@param filename string
---@return string
H.resolve_md_extension = function(filename)
  if string.find(filename:lower(), '%.md$') then
    return filename
  end
  return filename .. '.md'
end

---@param path string
---@return string
H.read_file = function(path)
  local lines = vim.fn.readfile(vim.fn.expand(path))
  local content = table.concat(lines, '\n')
  return content
end

---@param command string
---@param file*
H.execute_os_command = function(command)
  return assert(io.popen(command, 'r'))
end

---@param query string
---@return table
H.search_rg = function(query)
  local cmd = {
    'rg',
    '--no-config',
    '--fixed-strings',
    '--type=md',
    vim.fn.shellescape(query),
    Obsidian.config.dir,
    ' --json',
  }
  local result = {}
  local rg_result = H.execute_os_command(table.concat(cmd, ' '))
  for line in rg_result:lines() do
    local decoded = vim.json.decode(line)
    if decoded == nil then
      goto continue
    end
    if decoded['type'] ~= 'match' then
      goto continue
    end
    local match = {
      path = decoded['data']['path']['text'],
      text = decoded['data']['lines']['text'],
      cursor = {
        decoded['data']['line_number'],
        decoded['data']['submatches'][1]["start"]
      }
    }
    local preview = match.path:gsub(vim.fn.expand(Obsidian.config.dir), '') .. match.text
    result[#result + 1] = vim.tbl_deep_extend("keep", match, { preview = preview })
    ::continue::
  end
  return result
end

---Search file with some name in vault.
---@param filename string
---@return table
H.search_file = function(filename)
  local cmd = {
    'fd',
    '--full-path',
    Obsidian.config.dir,
    '|',
    'rg',
    vim.fn.shellescape("/" .. filename),
  }
  local result = {}
  local command_result = H.execute_os_command(table.concat(cmd, ' '))
  for line in command_result:lines() do
    result[#result + 1] = line
  end
  return result
end

---Search files in vault
---@param directory string
---@return table
H.get_list_of_files = function(directory)
  local cmd = {
    'fd',
    '--full-path',
    directory,
    '--type',
    'file'
  }
  local result = {}
  local command_result = H.execute_os_command(table.concat(cmd, ' '))
  for line in command_result:lines() do
    result[#result + 1] = line
  end
  return result
end

H.replace_in_vault = function(old, new)
  local cmd = {
    'fd',
    '--full-path',
    Obsidian.config.dir,
    '--type',
    'file',
    '--exec',
    'sd',
    '-s',
    '"' .. old .. '"',
    '"' .. new .. '"'
  }
  local command_result = H.execute_os_command(table.concat(cmd, ' '))
end

return Obsidian
