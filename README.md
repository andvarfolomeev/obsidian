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
- Multi vault

## Configuration example with lazy.nvim

You do not need to decorate functions in keys if you have only one vault in opts.vaults.

```lua
{
  'ada0l/obsidian',
  keys = {
    {
      '<leader>ov',
      function()
        Obsidian.select_vault()
      end,
      desc = "Select Obsidian vault",
    },
    {
      '<leader>oo',
      function()
        Obsidian.get_current_vault(function()
          Obsidian.cd_vault()
        end)
      end,
      desc = 'Open Obsidian directory',
    },
    {
      '<leader>ot',
      function()
        Obsidian.get_current_vault(function()
          Obsidian.open_today()
        end)
      end,
      desc = 'Open today',
    },
    {
      '<leader>od',
      function()
        Obsidian.get_current_vault(function()
          vim.ui.input({ prompt = 'Write shift in days: ' }, function(input_shift)
            local shift = tonumber(input_shift) * 60 * 60 * 24
            Obsidian.open_today(shift)
          end)
        end)
      end,
      desc = 'Open daily node with shift',
    },
    {
      '<leader>on',
      function()
        Obsidian.get_current_vault(function()
          vim.ui.input({ prompt = 'Write name of new note: ' }, function(name)
            Obsidian.new_note(name)
          end)
        end)
      end,
      desc = 'New note',
    },
    {
      '<leader>oi',
      function()
        Obsidian.get_current_vault(function()
          Obsidian.select_template('telescope')
        end)
      end,
      desc = 'Insert template',
    },
    {
      '<leader>os',
      function()
        Obsidian.get_current_vault(function()
          Obsidian.search_note('telescope')
        end)
      end,
      desc = 'Search note',
    },
    {
      '<leader>ob',
      function()
        Obsidian.get_current_vault(function()
          Obsidian.select_backlinks('telescope')
        end)
      end,
      desc = 'Select backlink',
    },
    {
      '<leader>og',
      function()
        Obsidian.get_current_vault(function()
          Obsidian.go_to()
        end)
      end,
      desc = 'Go to file under cursor',
    },
    {
      '<leader>or',
      function()
        Obsidian.get_current_vault(function()
          vim.ui.input({ prompt = 'Rename file to' }, function(name)
            Obsidian.rename(name)
          end)
        end)
      end,
      desc = 'Rename file with updating links',
    },
    {
      "gf",
      function()
        if Obsidian.found_wikilink_under_cursor() ~= nil then
          return "<cmd>lua Obsidian.get_current_vault(function() Obsidian.go_to() end)<CR>"
        else
          return "gf"
        end
      end,
      noremap = false,
      expr = true
    }
  },
  opts = function()
    ---@param filename string
    ---@return string
    local transformator = function(filename)
      if filename ~= nil and filename ~= '' then
        return filename
      end
      return string.format('%d', os.time())
    end
    return {
      vaults = {
        {
          dir = '~/Documents/Knowledge/',
          templates = {
            dir = 'templates/',
            date = '%Y-%d-%m',
            time = '%Y-%d-%m',
          },
          note = {
            dir = '',
            transformator = transformator,
          },
        },
        {
          dir = '~/Documents/SyncObsidian/',
          daily = {
            dir = '01.daily/',
            format = '%Y-%m-%d',
          },
          templates = {
            dir = 'templates/',
            date = '%Y-%d-%m',
            time = '%Y-%d-%m',
          },
          note = {
            dir = 'notes/',
            transformator = transformator,
          },
        }
      }
    }
  end
},
```

## Similar plugins

- [epwalsh/obsidian.nvim](https://github.com/epwalsh/obsidian.nvim)
