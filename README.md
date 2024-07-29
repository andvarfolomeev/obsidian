# Obsidian for Neovim (WIP)

I often use Obsidian to take daily notes and maintain my knowledge base.
This plugin allows you to use the basic functionality to work with Obsidian vaults.

For full experience needs [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) plugin, [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) plugin. And it also needs CLI tools like [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd) and [sd](https://github.com/chmln/sd).

See more details in [Features](#features) and [help file](doc/obsidian.txt).

## Features

- [x] Opening vault
- [x] Creating new notes
- [x] Creating/Opening daily notes
- [x] Selecting and inserting templates to buffer with support placeholders like: `{{title}}`, `{{date}}`, `{time}}`
- [x] Searching notes with Telescope integration
- [x] Searching backlinks of the current note
- [x] Going to file via wiki link
- [x] Renaming current note with updating wiki links
- [x] Autocomplete of wiki links with cmp integration
- [x] Multi vault

## Configuration example with lazy.nvim

You do not need to decorate functions in keys if you have only one vault in opts.vaults.

```lua
{
  'ada0l/obsidian',
  lazy = 'VeryLazy',
  keys = {
    { '<leader>ov', '<cmd>lua require("obsidian").vault_prompt()<cr>', desc = 'Vault prompt' },
    { '<leader>oc', '<cmd>lua require("obsidian").cd_vault()<cr>', desc = 'Cd vault' },
    { '<leader>on', '<cmd>lua require("obsidian").new_note_prompt()<cr>', desc = 'New note' },
    { '<leader>ot', '<cmd>lua require("obsidian").open_today()<cr>', desc = 'Open today' },
    { '<leader>oT', '<cmd>lua require("obsidian").open_today_prompt()<cr>', desc = 'Open today (shift)' },
    { '<leader>oi', '<cmd>lua require("obsidian").template_picker()<cr>', desc = 'Template picker' },
    { '<leader>of', '<cmd>lua require("obsidian").note_picker()<cr>', desc = 'Note picker' },
    { '<leader>ob', '<cmd>lua require("obsidian").backlinks_picker()<cr>', desc = 'Backlinks picker' },
    { '<leader>or', '<cmd>lua require("obsidian").rename_prompt()<cr>', desc = 'Rename prompt' },
    {
      'gf',
      function()
        if require('obsidian').found_wikilink_under_cursor() ~= nil then
          return '<cmd>lua require("obsidian").go_to()<CR>'
        else
          return 'gf'
        end
      end,
      noremap = false,
      expr = true,
    },
  },
  ---@type ObsidianOptions
  opts = {
    extra_fd_opts = '--exclude assets --exclude journals --exclude _debug_remotely_save',
    vaults = {
      {
        dir = '~/Knowledge/',
        daily = {
          dir = 'journals',
          format = '%Y-%m-%d',
        },
        note = {
          dir = '.',
          transformator = function(filename)
            if filename ~= nil and filename ~= '' then
              return filename
            end
            return string.format('%d', os.time())
          end,
        },
        templates = {
          dir = 'templates',
          date = '%Y-%d-%m',
          time = '%Y-%d-%m',
        },
      },
    },
  },
}
```

### Cmp integration

```lua
{
  'hrsh7th/nvim-cmp',
  dependencies = {
    'ada0l/obsidian',
  },
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    local cmp = require('cmp')
    local obsidian = require('obsidian')
    cmp.register_source('obsidian', obsidian.get_cmp_source().new())
    table.insert(opts.sources, { name = 'obsidian' })
  end,
},
```

## Similar plugins

- [epwalsh/obsidian.nvim](https://github.com/epwalsh/obsidian.nvim)
