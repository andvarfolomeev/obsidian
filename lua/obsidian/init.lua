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
---
---@param filename string
---@return string
H.resolve_md_extension = function(filename)
  print(string.find(filename:lower(), "%.md$"))
  if string.find(filename:lower(), "%.md$") then
    return filename
  end
  return filename .. ".md"
end

return Obsidian
