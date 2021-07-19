
# Vimpeccable

## Write your .vimrc in Lua!

Vimpeccable is a plugin for Neovim that adds a simple lua api to map keys directly to lua code.  This can be used to easily replace your vimscript-based `.vimrc` / `init.vim` with `init.lua` instead.

NOTE: Requires Neovim 0.5+

## Table of Contents

* [Quick Start Example](#quick-start-example)
* [Vimpeccable Command Syntax](#vimpeccable-command-syntax)
* [Runtime Reloading of Entire Vimrc Plugin](#runtime-reloading-of-entire-vimrc-plugin)
* [Repeatable Maps](#repeatable-maps)
* [Duplicate Map Detection](#duplicate-map-detection)
* [Chord Cancellation Maps](#chord-cancellation-maps)
* [Buffer Local Maps](#buffer-local-maps)
* [User Command Maps](#user-command-maps)

## Quick Start Example

Given the following example .vimrc:

```vimL
call plug#begin(stdpath('data') . '/plugged')
Plug 'morhetz/gruvbox'
call plug#end()

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

When using Neovim 0.5 and Vimpeccable, you could instead write it in lua or any lua-based language as well.  You can do this by creating an `init.lua` file instead of `init.vim` with contents:

```lua
vim.cmd 'packadd paq-nvim'

local paq = require('paq-nvim').paq
paq {'savq/paq-nvim', opt = true}

paq {'morhetz/gruvbox'}
paq {'svermeulen/vimpeccable'}

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true

vim.o.hidden = true

vim.o.history = 5000

vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop
vim.g.mapleader = " "

vim.cmd('colorscheme gruvbox')

-- Note that we are using 'vimp' (not 'vim') below to add the maps
-- vimp is shorthand for vimpeccable
local vimp = require('vimp')

vimp.nnoremap('<leader>hw', function()
  print('hello')
  print('world')
end)

-- Toggle line numbers
vimp.nnoremap('<leader>n', function()
  vim.wo.number = not vim.wo.number
end)

-- Keep the cursor in place while joining lines
vimp.nnoremap('J', 'mzJ`z')

vimp.nnoremap('<leader>ev', ':vsplit ~/.config/nvim/init.lua<cr>')
-- Or:
-- vimp.nnoremap('<leader>ev', [[:vsplit ~/.config/nvim/init.lua<cr>]])
-- Or:
-- vimp.nnoremap('<leader>ev', function()
--   vim.cmd('vsplit ~/.config/nvim/init.lua')
-- end)

vim.cmd('colorscheme gruvbox')
```

For the purposes of this example we use [paq-nvim](https://github.com/savq/paq-nvim) but you are of course free to use whichever plugin manager you prefer.

Then you can open Neovim and execute `:PaqInstall`, and then you should be able to execute all the maps from the example (eg. `<space>hw` to print 'hello world', `<space>ev` to open `init.lua`, etc.)

## Vimpeccable Command Syntax

Vimpeccable mirrors the standard vim API and so has all the variations of `nnoremap`, `nmap`, `xnnoremap`, etc. that you probably are already familiar with.

The standard format to add a mapping in vimscript is:

```
[MODE](nore?)map [OPTIONS] [LHS] [RHS]
```

Where:
- `MODE` can be one of `x`, `v`, `s`, `o`, `i`, `c`, `t`
- `nore` is optional and determines whether the command is 'recursive' or not.  Recursive here would, for example, allow executing other user-defined maps triggered from a user defined map.
- `OPTIONS` can be one or more options such as `<expr>`, `<buffer>`, `<nowait>` etc.

Examples:

```viml
nnoremap <leader>hw :echo 'hello world'<cr>

" Note that we need to use recursive here we are mapping to a non-default RHS
nmap <leader>c <plug>Commentary
xmap <leader>c <plug>Commentary

nnoremap <expr> <silent> <leader>t :call g:DoCustomThing()<cr>
```

Vimpeccable mirrors the above except that it is a lua method call and therefore requires that each parameter is seperated by commas:

```
vimp.[MODE](nore?)map [OPTIONS?], [LHS], [RHS]
```

Examples:

```lua
-- Note that in lua we can represent strings either with quotes or with double square brackets
vimp.nnoremap('<leader>hw', [[:echo 'hello world'<cr>]])

vimp.nmap('<leader>c', '<plug>Commentary')
vimp.xmap('<leader>c', '<plug>Commentary')

-- Also note that we need to pass the options as a list instead of as seperate parameters
-- Also note that unlike vimscript, the options are not surrounded with angle brackets
vimp.nnoremap({'expr', 'silent'}, '<leader>1', [[:call g:DoCustomThing()<cr>]])

-- Or, alternatively, implement DoCustomThing in lua instead:
vimp.nnoremap({'expr', 'silent'}, '<leader>1', function()
    -- Add logic here
end)
```

Vimpeccable also comes with extra methods named `bind` and `rbind` which allow passing the mode as a parameter instead of needing to use different methods:

```lua
vimp.bind('n', '<leader>hw', [[:echo 'hello world'<cr>]])

-- plugs need to use rbind
vimp.rbind('nx', '<leader>c', '<plug>Commentary')
```

Note that the only difference here is that `rbind` is 'recursive' so allows the use of custom user maps as part of the RHS value.

These methods can be especially useful to allow binding multiple modes at the same time.  Note also that you can pass multiple values for LHS like this as well:

```lua
vimp.rbind('nx', {'<leader>c', 'gc'}, '<plug>Commentary')
```

Which in vimscript would require 4 different statements for each variation.

## Runtime Reloading of Entire Vimrc Plugin

For many vimmers, It is common to regularly be making tweaks to your vimrc.

In order to make edits at runtime without requiring a full restart of vim, often what people do is open up their vimrc and then simply execute `:so %` to re-source it.  The lua equivalent of this would be `:luafile %`, however, if we were to attempt this when using vimpeccable we would get errors complaining about duplicate maps.  This is a [feature](#duplicate-map-detection), not a bug, and is helpful to avoid accidentally clobbering existing maps.  But how would we reload our vimpeccable config at runtime then?

To show how this is done, let's add the following to our `init.lua` from above:

```lua
-- r = reload vimrc
vimp.nnoremap('<leader>r', function()
  -- Remove all previously added vimpeccable maps
  vimp.unmap_all()
  -- Unload the lua namespace so that the next time require('config.X') is called
  -- it will reload the file
  require("config.util").unload_lua_namespace('config')
  -- Make sure all open buffers are saved
  vim.cmd('silent wa')
  -- Execute our vimrc lua file again to add back our maps
  dofile(vim.fn.stdpath('config') .. '/init.lua')

  print("Reloaded vimrc!")
end)
```

Let's also add a custom lua namespace, where we can place all our custom Lua that we'll want to reload.  We can do this by:
- Creating a new directory at `lua/config` next to our `init.lua`
- Creating a new file in this directory named `util.lua` with contents:

```lua
local M = {}

M['unload_lua_namespace'] = function(prefix)
  local prefix_with_dot = prefix .. '.'
  for key, value in pairs(package.loaded) do
    if key == prefix or key:sub(1, #prefix_with_dot) == prefix_with_dot then
      package.loaded[key] = nil
    end
  end
end

return M
```

Now we can open neovim again and execute `<space>r` to fully reload our config.  The call to `vimp.unmap_all` will remove all the maps that have been added via vimpeccable, and the call to `unload_lua_namespace` will clear all our custom lua code from the lua cache.  If we did not do the `unload_lua_namespace` step, and then changed something inside our `lua/config` directory, then that code would not be reloaded.

To test our new `<leader>r` reload mapping, try changing the `<leader>hw` mapping to print something different, then press `<space>r` and then `<space>hw` to see the new text.  Or, try adding another utility function to `util.lua` and then calling it from a new map, to ensure that code will be updated as well.

As your vimrc grows in complexity, you may want to split it up into multiple files, which we can now do easily in lua by using the `require` method.

## Repeatable Maps

Vimpeccable can also optionally make custom maps repeatable with the `.` key.  For example, given the following maps:

```lua
vimp.bind('[e', ':move--<cr>')
vimp.bind(']e', ':move+<cr>')
```

You might want to be able to hit `]e..` to move the current line three lines down.  By default this would not work.  You can fix this by making it repeatable by just passing in the `repeatable` option like this:

```lua
vimp.bind({'repeatable'}, '[e', ':move--<cr>')
vimp.bind({'repeatable'}, ']e', ':move+<cr>')
```

Note that this feature requires that [vim-repeat](https://github.com/tpope/vim-repeat) is installed.

## Duplicate Map Detection

By default, vimpeccable will reject any maps that are already taken.  To see what that looks like, try adding the following map to the same `vimrc.lua` (assuming you're using the config from above):

```lua
vimp.bind('<leader>hw', function() print('hi!') end)
```

If you then execute `<space>r`, you should see the following error or similar:

<img src="https://i.imgur.com/P1v3TLu.png">

This is because we have already defined a map for `<leader>hw` above this line.  Note that this error will not stop the rest of our config from loading.  By default, Vimpeccable will simply log the error and continue, to ensure as much as your config can be loaded as possible.

In some cases you might want to override the previous mapping anyway, which you can do by passing in the `override` option like this:

```lua
vimp.bind({'override'}, '<leader>hw', function() print('hi!') end)
```

If you then reload with `<space>r`, and press `<space>hw`, you should now see the new output.

Vimpeccable will also automatically detect maps that 'shadow' each other as well.  For example, if we change our map to this instead:

```lua
vimp.bind('<leader>h', function() print('hi!') end)
```

And then attempt to reload again with `<space>r`, we will get a similar error:

<img src="https://i.imgur.com/hGrtCCp.png">

This is different from vim's default behaviour.  If we added these maps using vimscript like this instead:

```viml
nnoremap <leader>hw :echo 'hello world'<cr>
nnoremap <leader>h :echo 'hi!'<cr>
```

Then every time we execute `<leader>h`, there would be a delay before we see the 'hi!' text printed, because vim needs to wait to see if you're in the process of executing `<leader>hw` instead.

## Chord Cancellation Maps

If you find yourself using a lot of leader maps, you might notice that it is not possible to cancel a leader operation without sometimes causing unintended side effects.  For example, given the following map:

```lua
vimp.bind('<leader>ddb', function() print("Executed map!") end)
```

If you then type `<space>dd` and then hit any key other than `b`, you will find that the current line is deleted.  This is because vim will do its best to try and match what you've already typed to another existing map, and in this case it chooses `dd` to delete the current line.  A similar problem occurs if we type `<space>d` and then hit any other key other than d, except in this case vim decides to just move the cursor one character to the right.

You can avoid these problems by adding the following to the bottom of your `vimrc.lua`:

```lua
vimp.add_chord_cancellations('n', '<leader>')
```

Now if we reload with `<space>r`, then hit `<space>dd<esc>`, then the line will no longer be deleted.  And similarly, if we hit `<space>d<esc>`, nothing will happen anymore.

Under the hood, what vimpeccable is actually doing here is adding maps for `<space>dd<esc>` and `<space>d<esc>` and explicitly mapping them to do nothing.

## Buffer Local Maps

Vimpeccable also supports buffer local maps.  Given this vimscript map:

```viml
nnoremap <buffer> <leader>t1 :echo 'buffer local map!'<cr>
```

As you might expect, the equivalent in lua would be:

```lua
vimp.nnoremap({'buffer'}, '<leader>t1', [[:echo 'buffer local map!'<cr>]])
vimp.nnoremap({'buffer'}, '<leader>t2', [[:echo 'another buffer local map!'<cr>]])
```

Or alternatively:

```lua
vimp.add_buffer_maps(function()
  vimp.nnoremap('<leader>t1', function() print('lua map!') end)
  vimp.nnoremap('<leader>t2', function() print('lua map two!') end)
end)
```

You can also specify the exact buffer if you know the buffer id like this:

```lua
vimp.add_buffer_maps(bufferId, function()
  vimp.nnoremap('<leader>t1', function() print('lua map!') end)
  vimp.nnoremap('<leader>t2', function() print('lua map two!') end)
end)
```
## Advanced Options

* `vimp.always_override` (default: `false`) 
    * When true, all maps will be added as if they always have the `override` option set
* `vimp.all_maps`
    * A dictionary containing the full list of maps and their associated info
* `vimp.current_map_info`
    * A table of info for the currently executing map
* `vimp.maps_in_progress`
    * A collection of all maps that are currently executing

## User Command Maps

In some cases it might be better to define a custom action as a vim command rather than mapping it to a key.  This way we don't use up any open key maps and our custom commands are discoverable on the command line by pressing tab (which can be easier than having to remember whatever leader map we chose). For example, you might want to define the following user commands in vimscript:

```viml
function! g:OpenFileOnGithub()
    echom "Open the URL on github for current file on current line"
endfunction

function! g:RenameFile(newName)
    echom "Todo - rename current file to " . a:newName
endfunction

command! -nargs=0 SvOpenFileOnGithub call g:OpenFileOnGithub()
command! -nargs=* SvRename call g:RenameFile(<f-args>)
```

Note here that I'm using `Sv` as a prefix on my commands so that I can just type `Sv<tab>` on the command line to see the full list.

To do this in lua with vimpeccable instead, you could do this:

```lua
vimp.map_command('SvOpenFileOnGithub', function()
  print("Todo - Open the URL on github for current file on current line")
end)

vimp.map_command('SvRename', function(newName)
  print("Todo - rename current file to " .. newName)
end)
```

Note that vimpeccable will automatically fill in the `nargs` value for the command based on the given function signature.

