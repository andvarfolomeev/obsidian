Obsidian for Neovim (WIP)
=============

I often use Obsidian to take daily notes and maintain my knowledge base. This plugin allows you to use the basic functionality to work with Obsidian vaults.

For full experience needs [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) plugin (some search related features don't work without it).

See more details in [Features](#features) and [help file](doc/obsidian.txt).

## Features

- Opening vault
- Creating new notes
- Creating/Opening daily notes
- Selecting and inserting templates to buffer with support placeholders like: ``{{title}}``, ``{{date}}``, ``{time}}``
- Searching notes with Telescope integration
- Searching backlinks of the current note

## Configuration example with lazy.nvim

```lua
{
  'ada0l/obsidian',
  keys = {
    {
      '<leader>oo',
      function()
        Obsidian.cd_vault()
      end,
      desc = 'Open Obsidian directory',
    },
    {
      '<leader>ot',
      function()
        Obsidian.open_today()
      end,
      desc = 'Open today',
    },
    {
      '<leader>od',
      function()
        vim.ui.input({ prompt = 'Write shift in days: ' }, function(input_shift)
          local shift = tonumber(input_shift) * 60 * 60 * 24
          Obsidian.open_today(shift)
        end)
      end,
      desc = 'Open daily node with shift',
    },
    {
      '<leader>on',
      function()
        vim.ui.input({ prompt = 'Write name of new note: ' }, function(name)
          Obsidian.new_note(name)
        end)
      end,
      desc = 'New note',
    },
    {
      '<leader>oi',
      function()
        Obsidian.select_template('telescope')
      end,
      desc = 'Insert template',
    },
    {
      '<leader>os',
      function()
        Obsidian.search_note('telescope')
      end,
      desc = 'Search note',
    },
    {
      '<leader>ob',
      function()
        Obsidian.select_backlinks('telescope')
      end,
      desc = 'Select backlink',
    },
  },
  opts = {
    dir = '~/Documents/SyncObsidian/',
  },
},
```

## Configuration options

```lua
{
  -- Optional, the path to vault directory
  dir = '~/ObsidianVault/',

  daily = {
    -- Optional, the path to daily notes directory
    dir = 'daily/', -- Optional, It is mean that daily note directory is ~/ObsidianVault/daily/
    format = '%Y-%m-%d', -- Optional, format file names
  },
  templates = {
    -- Optional, the path to templates directory
    dir = 'templates/',
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
```
