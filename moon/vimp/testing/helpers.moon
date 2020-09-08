
assert = require("vimp.util.assert")
stringUtil = require("vimp.util.string")

class Helpers
  -- recursive input
  rinput: (keys) ->
    rawKeys = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(rawKeys, 'mx', false)

  -- non recursive input
  input: (keys) ->
    rawKeys = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(rawKeys, 'nx', false)

  getCursorColumn: ->
    pos = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
    return pos[2]

  getCursorCharacter: ->
    return stringUtil.charAt(Helpers.getLine!, Helpers.getCursorColumn! + 1)

  setLines: (lines) ->
    bufferHandle = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(bufferHandle, 0, -1, false, lines)

  getLine: ->
    return vim.api.nvim_get_current_line()

  unlet: (name) ->
    -- This if is necessary for now but nvim might fix this
    -- The docs suggest that 'vim.g.foo = nil' should behave
    -- similar to unlet
    if vim.g[name] != nil
      vim.g[name] = nil

  hasSameContents: (list1, list2) ->
    if #list1 != #list2
      return false

    map1 = {x,true for x in *list1}

    for item in *list2
      if map1[item] == nil
        return false

    return true

  assertSameContents: (list1, list2) ->
    assert.that(Helpers.hasSameContents(list1, list2), "Expected '#{vim.inspect(list1)}' to equal '#{vim.inspect(list2)}'")

