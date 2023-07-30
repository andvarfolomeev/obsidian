--- Obsidian
---
--- Structure of project inpired by echasnovski/mini.nvim
---
---@alias __obsidian_options table|nil
---
---@diagnostic disable:undefined-field
---@diagnostic disable:discard-returns
---@diagnostic disable:unused-local
---@diagnostic disable:cast-local-type

local Obsidian = {}
local H = {}

local default_config = {}

---@param opts __obsidian_options
Obsidian.setup = function(opts)
  _G.Obsidian = Obsidian
  config = H.setup_config(opts)
  H.apply_config(config)
  H.create_autocommands(config)
  H.create_default_hl()
end

Obsidian.config = {
  dir = '~/ObsidianVault/',
  daily = {
    dir = 'daily/',
    format = '%Y-%m-%d',
  },
  templates = {
    dir = 'templates/',
  },
  note = {
    dir = 'notes/',
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

Obsidian.cd_vault = function()
  vim.api.nvim_command('cd ' .. Obsidian.config.dir)
end

---@param filename string
Obsidian.new_note = function(filename)
  local filepath = H.prepare_path(
    Obsidian.config.note.transformator(filename),
    Obsidian.config.note.dir,
    true
  )
  vim.api.nvim_command('edit ' .. filepath)
end

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

---@param template_content string
---@param filename string
---@return string
Obsidian.generate_template = function(template_content, filename)
  local title_ = filename:gsub('%.md$', '')
  local date = os.date('%Y-%m-%d')
  local time = os.date('%H-%M')
  local result = template_content
      :gsub('{{%s*title%s*}}', title_)
      :gsub('{{%s*date%s*}}', date)
      :gsub('{{%s*time%s*}}', time)
  return result
end

---Insert template to current buffer
---@param template_path string
Obsidian.insert_template = function(template_path)
  local processed_template =
      Obsidian.generate_template(H.read_file(template_path), vim.fn.expand('%:t'))
  vim.api.nvim_paste(processed_template, true, 1)
end

---@param callback function
---@param method_str string
Obsidian.select_template = function(callback, method_str)
  local methods = {
    native = Obsidian.select_template_native,
    telescope = Obsidian.select_template_telescope,
  }
  local method = methods[method_str]
  if method then
    method(callback)
  else
    Obsidian.select_template_native(callback)
  end
end

Obsidian.select_template_native = function(callback)
  local template_files =
      vim.fn.glob(Obsidian.config.templates.dir .. '*', false, true)
  vim.ui.select(template_files, {
    prompt = 'Select template: ',
  }, callback)
end

Obsidian.select_template_telescope = function(callback)
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local find_files = require('telescope.builtin').find_files
  find_files({
    prompt_title = 'Select template',
    cwd = Obsidian.config.templates.dir,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        callback(Obsidian.config.templates.dir .. selection[1])
      end)
      return true
    end,
  })
end

Obsidian.search_note = function(callback)
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local find_files = require('telescope.builtin').find_files
  find_files({
    prompt_title = 'Select template',
    cwd = Obsidian.config.dir,
  })
end

---Validating user configuration that it is correct
---@param opts __obsidian_options
---@return __obsidian_options
H.setup_config = function(opts)
  return opts
end

---Apply user configuration
---@param opts __obsidian_options
H.apply_config = function(opts)
  Obsidian.config = vim.tbl_deep_extend('force', Obsidian.config, opts)
end

---@param opts __obsidian_options
H.create_autocommands = function(opts) end

---@param opts __obsidian_options
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
    H.create_dir_force(dir)
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

return Obsidian
