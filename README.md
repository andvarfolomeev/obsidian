# Obsidian for Neovim (WIP)

I often use Obsidian to take daily notes and maintain my knowledge base. This plugin allows you to use the basic functionality to work with Obsidian vaults.

For full experience needs [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) plugin, [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) plugin. And it also needs CLI tools like [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd) and [sd](https://github.com/chmln/sd).

See more details in [Features](#features) and [help file](doc/obsidian.txt).

## Features

- Opening vault
- Creating new notes
- Creating/Opening daily notes
- Selecting and inserting templates to buffer with support placeholders like: `{{title}}`, `{{date}}`, `{time}}`
- Searching notes with Telescope integration
- Searching backlinks of the current note
- Going to file via wiki link
- Renaming current note with updating wiki links
- Autocomplete of wiki links with cmp integration

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
