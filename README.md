Obsidian for Neovim (WIP)
=============

# Configuration example with lazy.nvim

```lua
{
  'ada0l/obisidian',
  keys = {
    {
      '<leader>oi',
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
        Obsidian.select_template(function(template_path)
          Obsidian.insert_template(template_path)
        end, 'native')
      end,
      desc = 'Insert template',
    },
    {
      '<leader>os',
      function()
        Obsidian.search_note()
      end,
      desc = 'New note',
    },
  },
  opts = {
    dir = '~/Documents/SyncObsidian/',
    transformator = function(filename)
    return "123"
    end
  },
},
```

# Configuration options

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

# TODO
- [x] cd vault
- [x] create new note
- [ ] apply template
    - [x] generate template
    - [x] insert template
    - [x] selection of template
    - [x] search templates with ```vim.fn.glob``` and ```vim.ui.select```
    - [x] search templates with telescope
    - [ ] support of Moment.js format tokens for ```{{date}}``` and ```{{time}}```
- [x] search notes (integration with telescope/fzf.nvim)
- [x] open today note
- [ ] backlinks
