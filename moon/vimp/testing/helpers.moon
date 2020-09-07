
class Helpers
  -- recursive input
  rinput: (keys) ->
    rawKeys = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(rawKeys, 'mx', false)

  -- non recursive input
  input: (keys) ->
    rawKeys = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(rawKeys, 'nx', false)

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

