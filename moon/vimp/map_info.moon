
assert = require("vimp.util.assert")

class MapInfo
  new: (id, mode, options, extraOptions, actualLhs, lhs, rhs, bufferHandle) =>
    @id = id
    @lhs = lhs
    @actualLhs = actualLhs
    @rhs = rhs
    @options = options
    @extraOptions = extraOptions
    @mode = mode
    @bufferHandle = bufferHandle

  _getActualRhs: =>
    if type(@rhs) == 'string'
      return @rhs

    assert.that(type(@rhs) == 'function')

    -- Note that we use _vimp directly instead of vimp here, because
    -- we want to bypass the error handling stuff, because we are
    -- already handling errors in _executeMap
    if @options.expr
      return "luaeval('_vimp:_executeMap(#{@id})')"

    assert.that(@mode != 'c',
      "Lua function maps for command mode are not currently supported.  Can you use an <expr> lua function instead?")

    assert.that(@mode != 't',
      "Lua function maps for terminal mode are not currently supported.  Can you use an <expr> lua function instead?")

    assert.that(@options.noremap, "Cannot use recursive mapping with lua function")

    if @mode == 'i'
      return "<c-o>:lua _vimp:_executeMap(#{@id})<cr>"

    if @mode == 's'
      return "<esc>:lua _vimp:_executeMap(#{@id})<cr>"

    -- This should work for normal, visual, and operation mode
    return ":<c-u>lua _vimp:_executeMap(#{@id})<cr>"

  getRhsDisplayText: =>
    if type(@rhs) == 'string'
      return @rhs

    assert.that(type(@rhs) == 'function')
    return "<lua function #{@id}>"

  addToVim: =>
    actualRhs = @\_getActualRhs!
    if @bufferHandle != nil
      vim.api.nvim_buf_set_keymap(@bufferHandle, @mode, @actualLhs, actualRhs, @options)
    else
      vim.api.nvim_set_keymap(@mode, @actualLhs, actualRhs, @options)

  removeFromVim: =>
    if @bufferHandle != nil
      vim.api.nvim_buf_del_keymap(@bufferHandle, @mode, @actualLhs)
    else
      vim.api.nvim_del_keymap(@mode, @actualLhs)

  toString: =>
    return "'#{@lhs}' -> '#{@\getRhsDisplayText!}'"

