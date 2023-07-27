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

H.setup_config = function(opts)
  return opts
end
H.apply_config = function(opts)
  Obsidian = opts
end
H.create_autocommands = function(opts) end
H.create_default_hl = function(opts) end

return Obsidian
