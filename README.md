Obsidian for Neovim (WIP)
=============

I often use Obsidian to take daily notes and maintain my own knowledge base. This plugin allows you to use the basic functionality to work with Obsidian vaults.

# Configuration example with lazy.nvim

```lua
{
  'ada0l/obsidian',
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
      '<leader>od',
      function ()
        vim.ui.input({ prompt = 'Write shift in days: ' }, function(input_shift)
          local shift = tonumber(input_shift) * 60 * 60 * 24
          Obsidian.open_today(shift)
        end)
      end,
      desc = 'Open daily node with shift'
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

# Available functions

- ```obsidian.cd_vault()``` - This moves your working directory to the vault.
- ```obsidian.open_today(shift)``` - This opens today note in daily note directory. The shift parameter is optional, but you can pass in order to set the offset from the current time.
- ```obsidian.new_note(note_name)``` - This opens note in general note directory.
- ```obsidian.select_template(callback, method)``` - This opens the note template selection and passes the selected path to the selected template to the callback. The second parameter specifies the method for displaying the modal select box. Use ```"native"``` if you don't want to use dependencies. Use a ```"telescope"``` if you already use a telescope.
- ```Obsidian.insert_template(template_path)``` - This applies the template and pastes it into the buffer.
- ```Obsidian.search_note()``` - This searches notes in the vault. Now it only works with a telescope.

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
