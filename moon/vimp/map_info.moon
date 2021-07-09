
assert = require("vimp.util.assert")

class MapInfo
  new: (id, mode, options, extra_options, lhs, expanded_lhs, raw_lhs, rhs, buffer_handle, context_info) =>
    @id = id
    @lhs = lhs
    @expanded_lhs = expanded_lhs
    @raw_lhs = raw_lhs
    @rhs = rhs
    @options = options
    @extra_options = extra_options
    @mode = mode
    @buffer_handle = buffer_handle
    @context_info = context_info

  _get_actual_rhs: =>
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

  get_rhs_display_text: =>
    result = None

    if type(@rhs) == 'string'
      result = @rhs
    else
      assert.that(type(@rhs) == 'function')
      result = "<lua function #{@id}>"

    return result

  add_to_vim: =>
    actualRhs = @\_get_actual_rhs!
    if @buffer_handle != nil
      vim.api.nvim_buf_set_keymap(@buffer_handle, @mode, @expanded_lhs, actualRhs, @options)
    else
      vim.api.nvim_set_keymap(@mode, @expanded_lhs, actualRhs, @options)

  remove_from_vim: =>
    if @buffer_handle != nil
      vim.api.nvim_buf_del_keymap(@buffer_handle, @mode, @expanded_lhs)
    else
      vim.api.nvim_del_keymap(@mode, @expanded_lhs)

  to_string: =>
    result = "'#{@lhs}' -> '#{@\get_rhs_display_text!}'"

    if @context_info != nil
      result ..= " with context: " .. tostring(@context_info)

    return result


