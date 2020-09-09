
# Vimpeccable:  Write your .vimrc in Lua!

# Introduction

Vimpeccable is a plugin for Neovim that allows you to easily replace your vimscript-based `.vimrc` with a lua-based one instead.  This plugin adds to the existing Neovim lua API by adding commands to easily add maps directly from lua.

# Quick Start Example

Given the following .vimrc:

```vimL
set ignorecase
set smartcase
set incsearch

set history=5000

set tabstop=4
set shiftwidth=4

let mapleader = "\<space>"

nnoremap <leader>hw :echo 'hello world'<cr>

" Toggle line numbers
nnoremap <leader>n :setlocal number!<cr>

" Keep the cursor in place while joining lines
nnoremap J mzJ`z

nnoremap <leader>ev :vsplit ~/.config/nvim/init.vim<cr>

colorscheme gruvbox
```

When using this plugin, you could instead write it in lua or any lua-based language as well.  For example, you could write it in MoonScript:

```moonscript
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true

vim.o.history = 5000

vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop

vim.g.mapleader = " "

vim.cmd('colorscheme gruvbox')

-- Note that we are using 'vimp' (not 'vim') below to add the maps
-- vimp is shorthand for vimpeccable

require('vimp')

-- Toggle line numbers
-- Note here that we are directly mapping a moonscript function directly
-- to the <leader>n keys
vimp.nnoremap '<leader>n', -> vim.wo.number = not vim.wo.number

-- Keep the cursor in place while joining lines
vimp.nnoremap 'J', 'mzJ`z'

vimp.nnoremap '<leader>hw', ->
  -- Note that we can easily create multi-line functions here
  print('hello')
  print('world')

-- Edit the primary vimrc
vimp.nnoremap '<leader>ev', -> vim.cmd('vsplit ~/.config/nvim/init.vim')
-- This would work too:
-- vimp.nnoremap '<leader>ev', [[:vsplit ~/.config/nvim/init.vim<cr>]]
-- Or this:
-- vimp.nnoremap '<leader>ev', ':vsplit ~/.config/nvim/init.vim<cr>'
```

Or lua directly:

```lua
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true

vim.o.history = 5000

vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop
vim.g.mapleader = " "

vim.cmd('colorscheme gruvbox')

-- Note that we are using 'vimp' (not 'vim') below to add the maps
-- vimp is shorthand for vimpeccable

require('vimp')

vimp.nnoremap('<leader>hw', function()
  print('hello')
  print('world')
end)

-- Toggle line numbers
-- Note here that we are directly mapping a lua function 
-- to the <leader>n keys
vimp.nnoremap('<leader>n', function()
  vim.wo.number = not vim.wo.number
end)

-- Keep the cursor in place while joining lines
vimp.nnoremap('J', 'mzJ`z')

vimp.nnoremap('<leader>ev', [[:vsplit ~/.config/nvim/init.vim<cr>]])
-- Or alternatively:
-- vimp.nnoremap('<leader>ev', function()
--   vim.cmd('vsplit ~/.config/nvim/init.vim')
-- end)

vim.cmd('colorscheme gruvbox')
```

You can also use any other lua-based language such as Fennel, Teal, etc. in similar fashion.

# Vimpeccable Features

* Binding maps directly to a lua function
* Hot reloading of entire config
* Detection of duplicate maps
* Detection of shadowed maps
* Built in support to make any map repeatable
* Better lua stack traces
* Better error handling for lua maps
* Add maps to non-active buffers
* Ability to create lua based user commands
* Ability to map multiple keys at once
* Support for key aliases
* Context info for current map being executed
* Chord cancellation maps

Usage

TBD

Things to Document

* Buffer local blocks

Notes

* Uses <unique> by default
* map command does not support completion yet

Things to document
* <unique> is off by default for buffer maps
* showmaps and showAllMaps functions


