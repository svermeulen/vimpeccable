
assert = require("vimp.util.assert")
string_util = require("vimp.util.string")

class Helpers
  -- recursive input
  rinput: (keys) ->
    raw_keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(raw_keys, 'mx', false)

  -- non recursive input
  input: (keys) ->
    raw_keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(raw_keys, 'nx', false)

  get_cursor_column: ->
    pos = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
    return pos[2]

  get_cursor_character: ->
    return string_util.char_at(Helpers.get_line!, Helpers.get_cursor_column! + 1)

  set_lines: (lines) ->
    buffer_handle = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buffer_handle, 0, -1, false, lines)

  get_line: ->
    return vim.api.nvim_get_current_line()

  unlet: (name) ->
    -- This if is necessary for now but nvim might fix this
    -- The docs suggest that 'vim.g.foo = nil' should behave
    -- similar to unlet
    if vim.g[name] != nil
      vim.g[name] = nil

  has_same_contents: (list1, list2) ->
    if #list1 != #list2
      return false

    map1 = {x,true for x in *list1}

    for item in *list2
      if map1[item] == nil
        return false

    return true

  assert_same_contents: (list1, list2) ->
    assert.that(Helpers.has_same_contents(list1, list2), "Expected '#{vim.inspect(list1)}' to equal '#{vim.inspect(list2)}'")

