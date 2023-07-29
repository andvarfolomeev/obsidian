--- Obsidian
---
--- Structure of project inpired by echasnovski/mini.nvim
---
---@diagnostic disable:undefined-field
---@diagnostic disable:discard-returns
---@diagnostic disable:unused-local
---@diagnostic disable:cast-local-type

local Obsidian = {}
local H = {}

local default_config = {}

Obsidian.setup = function(opts)
  _G.Obsidian = Obsidian
  config = H.setup_config(opts)
  H.apply_config(config)
  H.create_autocommands(config)
  H.create_default_hl()
end

Obsidian.config = {
  dir = "~/Documents/Brain",
  daily = {
    enabled = true,
    dir = "daily/",
  },
  note = {
    dir = "notes/",
    transformator = function() end,
  },
  mappings = {},
}

Obsidian.cd_vault = function()
  vim.api.nvim_command("cd " .. Obsidian.config.dir)
end

---@param filename string
Obsidian.new_note = function(filename)
  local processed_filename = H.resolve_md_extension(Obsidian.config.note.transformator(filename))
  local dir = Obsidian.config.dir .. Obsidian.config.note.dir
  if H.directory_exist(dir) then
    H.create_dir_force(dir)
  end
  local filepath = Obsidian.config.dir .. Obsidian.config.note.dir .. processed_filename
  vim.api.nvim_command("edit " .. filepath)
end

Obsidian.open_today = function()
  local processed_filename = H.resolve_md_extension(os.date(Obsidian.config.daily.format))
  local dir = Obsidian.config.dir .. Obsidian.config.daily.dir
  if H.directory_exist(dir) then
    H.create_dir_force(dir)
  end
  local filepath = Obsidian.config.dir .. Obsidian.config.note.dir .. processed_filename
  vim.api.nvim_command("edit " .. filepath)
end

H.setup_config = function(opts)
  return opts
end
H.apply_config = function(opts)
  Obsidian.config = opts
end
H.create_autocommands = function(opts) end
H.create_default_hl = function(opts) end
H.directory_exist = function(path)
  return vim.fn.isdirectory(path)
end
H.create_dir_force = function(path)
  vim.fn.mkdir(path, "p")
end
H.prepare_path = function(opts)
  local processed_filename = H.resolve_md_extension(opts.filename)
  local dir = Obsidian.config.dir .. opts.subdir
  if opts.create_dir and not H.directory_exist(dir) then
    H.create_dir_force(dir)
  end
  local filepath = Obsidian.config.dir .. opts.subdir .. processed_filename
  return filepath
end
---
---@param filename string
---@return string
H.resolve_md_extension = function(filename)
  if string.find(filename:lower(), "%.md$") then
    return filename
  end
  return filename .. ".md"
end

return Obsidian
