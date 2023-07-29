--- Obsidian
---
--- Structure of project inpired by echasnovski/mini.nvim
---
---@alias __obsidian_options table|nil
---@alias __obsidian_prepare_path_options table
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
  dir = '~/Documents/Brain/',
  daily = {
    enabled = true,
    dir = 'daily/',
  },
  note = {
    dir = 'notes/',
    transformator = function(filename)
      return filename
    end,
  },
  mappings = {},
}

Obsidian.cd_vault = function()
  vim.api.nvim_command('cd ' .. Obsidian.config.dir)
end

---@param filename string
Obsidian.new_note = function(filename)
  local filepath = H.prepare_path({
    subdir = Obsidian.config.note.dir,
    filename = Obsidian.config.note.transformator(filename),
    create_dir = true,
  })
  vim.api.nvim_command('edit ' .. filepath)
end

Obsidian.open_today = function()
  local filepath = H.prepare_path({
    subdir = Obsidian.config.daily.dir,
    filename = os.date(Obsidian.config.daily.format),
    create_dir = true,
  })
  vim.api.nvim_command('edit ' .. filepath)
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
  Obsidian.config = opts
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
---@param opts __obsidian_prepare_path_options
---@return string
H.prepare_path = function(opts)
  local processed_filename = H.resolve_md_extension(opts.filename)
  local dir = Obsidian.config.dir .. opts.subdir
  if opts.create_dir and not H.directory_exist(dir) then
    H.create_dir_force(dir)
  end
  local filepath = Obsidian.config.dir .. opts.subdir .. processed_filename
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

return Obsidian
