
# Vimpeccable

## Introduction: Write your .vimrc in Lua!

Vimpeccable is a plugin for Neovim that allows you to easily replace your vimscript-based `.vimrc` with a lua-based one instead.  This plugin adds to the existing Neovim lua API by adding commands to easily add maps directly from lua.

## Quick Start Example

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
-- Note here that we are directly mapping a moonscript function
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

# Table of Contents

* [Installation and Usage](#installation-and-usage)
* [Easy Hot Reloading of Entire Vimrc Plugin](#easy-hot-reloading-of-entire-vimrc-plugin)
* Automatic detection of duplicate/shadowed maps
* Repeatable Maps
* Better Error Handling
* User Commands Maps
* Key Aliases
* Chord Cancellation Maps
* Context info for current map being executed

# Installation and Usage (lua)

To use the example lua vimrc displayed above, you can start by changing your neovim `init.vim` file to the following:

```vimL
call plug#begin()
Plug 'svermeulen/vimpeccable-lua-vimrc-example'
Plug 'svermeulen/vimpeccable'
Plug 'morhetz/gruvbox'
call plug#end()
```

For the purposes of this example we will use [vim-plug](https://github.com/junegunn/vim-plug) but you are of course free to use whichever plugin manager you prefer.

Then, open Neovim, execute `:PlugInstall`, and then you should be able to execute all the maps from the example (eg. `<space>hw` to print 'hello world')

If you then look inside the `~/.config/nvim/plugged/vimpeccable-lua-vimrc-example` directory, you should see two files: `/lua/vimrc.lua` and `/plugin/vimrc.vim`.  Inside vimrc.vim all it does is the load `vimrc.lua` like this:

```vimL
lua require('vimrc')
```

This file is necessary because Neovim does not have support yet for directly executing lua yet, however this [is planned](https://github.com/neovim/neovim/pull/8720).  In the meantime, we need to bootstrap our lua vimrc with this `vimrc.vim` file.  Note that this works because vim will automatically source any `.vim` files found inside a `plugin` directory inside a plugin.  And when executing `lua require('vimrc')`, neovim will look for a file named `vimrc.lua` in all the `lua` directories on the `runtimepath`, and then execute that.

To view the `vimrc.lua` file, press `<space>ev`, which you will see is the same as the quickstart lua config example posted above.

# Installation and Usage (moonscript)

As mentioned, you can also implement your vimrc using any language that compiles to lua, such as MoonScript.  You can do this by changing your neovim `init.vim` file to the following:

```vimL
call plug#begin()
Plug 'svermeulen/nvim-moonmaker'
Plug 'svermeulen/vimpeccable-moonscript-vimrc-example'
Plug 'svermeulen/vimpeccable'
Plug 'morhetz/gruvbox'
call plug#end()
```

Before opening neovim you will also need to make sure that you have MoonScript installed and then `moonc` is available on the command line.  Then, as before, you can open up neovim, execute `:PlugInstall`, and then you should be able to execute all the maps from the example (eg. `<space>hw` to print 'hello world')

Note that in this case we added an extra plugin above named `nvim-moonmaker`.  This plugin does the work of lazily compiling our moonscript files to lua, which is necessary because neovim does not support moonscript out of the box.  See the [nvim-moonmaker](https://github.com/svermeulen/nvim-moonmaker) page for more details.

To view the `vimrc.moon` file, press `<space>ev`, which you will see is the same as the quickstart moonscript config example posted above.

# Vimpeccable Command Syntax

Vimpeccable mirrors the standard vim API and so has all the variations of `nnoremap`, `nmap`, `xnnoremap`, etc. that you probably are already familiar with.  See the following for some common vimL commands and their vimpeccable lua equivalents:

As a reminder, the standard format to add a mapping in vimscript is:

```
[MODE](nore?)map [OPTIONS] [LHS] [RHS]
```

Where:
- `MODE` can be one of `x`, `v`, `s`, `o`, `i`, `c`, `t`
- `nore` is optional and determines whether the command is recursive or not
- `OPTIONS` can be one or more options 

Examples:

```viml
nnoremap <leader>hw :echo 'hello world'<cr>

" Need to use recursive maps for plugs:
nmap <leader>c <plug>Commentary
xmap <leader>c <plug>Commentary

nnoremap <expr> <silent> <leader>1 :call g:DoCustomThing()<cr>
```

Vimpeccable mirrors the above except that it is a lua method call and therefore requires that each parameter is seperated by commas:

```
vimp.[MODE](nore?)map [OPTIONS?], [LHS], [RHS]
```

Examples:

```lua
-- In lua we can represent strings either with quotes or with double square brackets
vimp.nnoremap('<leader>hw', [[:echo 'hello world'<cr>]])

vimp.nmap('<leader>c', '<plug>Commentary')
vimp.xmap('<leader>c', '<plug>Commentary')

-- Also note that we need to pass the options as a list instead of as seperate parameters
-- Also note the options are not surrounded with angle brackets
vimp.nnoremap({'expr', 'silent'}, '<leader>1', [[:call g:DoCustomThing()<cr>]])

-- Or, alternatively, implement DoCustomThing in lua instead:
vimp.nnoremap({'expr', 'silent'}, '<leader>1', function()
    -- Add logic here
end)
```

Vimpeccable also comes with extra methods named `bind` and `rbind` which allow passing the mode as a parameter instead of needing to use different methods:

```lua
vimp.bind 'n', '<leader>hw', [[:echo 'hello world'<cr>]]

-- plugs need to use rbind
vimp.rbind 'nx', '<leader>c', '<plug>Commentary'
```

This can be especially useful to allow binding multiple modes at the same time.

Note also that you can pass multiple values for LHS like this:

```
vimp.rbind 'nx', {'<leader>c', 'gc'}, '<plug>Commentary'
```

Which in vimscript would require 4 different statements for each variation.

# Easy Hot Reloading of Entire Vimrc Plugin

It is common to regularly be making tweaks to your vimrc.  In order to make edits at runtime without requiring a full restart of vim, often what people do is open up their vimrc and then simply execute `:so %` to re-source it.  The lua equivalent of this would be `:luafile %`, however, if we were to attempt this when using vimpeccable we would get errors complaining about duplicate maps.






# Duplicate Map Detection





* Buffer local blocks

Notes

* Uses <unique> by default
* map command does not support completion yet

Things to document
* <unique> is off by default for buffer maps
* showmaps and showAllMaps functions


