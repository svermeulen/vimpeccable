
assert = require("vimp.util.assert")
log = require("vimp.util.log")
table_util = require("vimp.util.table")
string_util = require("vimp.util.string")

bind_methods = {
  'bind', 'rbind', 'nnoremap', 'inoremap', 'xnoremap',
  'vnoremap', 'onoremap', 'snoremap', 'cnoremap', 'tnoremap',
  'nmap', 'imap', 'xmap', 'vmap', 'omap', 'smap', 'cmap', 'tmap'}

get_extra_context = (member, args) ->
  if table_util.contains(bind_methods, member)
    -- Try and add some more context info
    -- If this fails then just ignore
    success, ret_value = pcall ->
      modes, options, extra_options, lhs_list, rhs = _vimp\_convert_args(unpack(args))
      local lhs
      if #lhs_list == 1
        lhs = lhs_list[1]
      else
        lhs = vim.inspect(lhs_list)
      return " when mapping '#{lhs}' for mode '#{modes}'"
    if success
      return ret_value

  return ''

-- We assume here that _vimp has been set already
return ->
  _getters = {
    total_num_maps: _vimp\_get_total_num_maps,
    map_error_handling_strategies: _vimp\_get_map_error_handling_strategies,
    map_error_handling_strategy: _vimp\_get_map_error_handling_strategy,
    aliases: _vimp\_get_aliases,
    maps_in_progress: _vimp\_get_maps_in_progress,
    current_map_info: _vimp\_get_current_map_info,
  }
  _setters = {
    map_error_handling_strategy: _vimp\_set_map_error_handling_strategy,
    print_min_log_level: _vimp\_set_print_min_log_level,
    map_context_provider: _vimp\_set_map_context_provider
  }

  _getters_deprecated = {
    totalNumMaps: _vimp\_get_total_num_maps,
    mapErrorHandlingStrategies: _vimp\_get_map_error_handling_strategies,
    mapErrorHandlingStrategy: _vimp\_get_map_error_handling_strategy,
    mapsInProgress: _vimp\_get_maps_in_progress,
    currentMapInfo: _vimp\_get_current_map_info,
  }
  _setters_deprecated = {
    mapErrorHandlingStrategy: _vimp\_set_map_error_handling_strategy,
    printMinLogLevel: _vimp\_set_print_min_log_level,
  }

  return setmetatable({}, {
    __index: (t, k) ->
      getter = _getters[k]

      if getter != nil
        return getter!

      getter = _getters_deprecated[k]

      if getter != nil
        log.warning("Field 'vimp.#{k}' is deprecated.  Use the snake_case version instead!")
        return getterDeprecated!

      func = _vimp[k]

      if func == nil
        error("No member found named 'vimp.#{k}'")

      assert.that(k\sub(1,1) != '_', "Attempted to call private method vimp.#{k}. This is not allowed")

      wrapped_func = (...) ->
        args = {...}
        action = -> func(_vimp, unpack(args))
        strategy = _vimp\_get_map_error_handling_strategy!
        strategies = _vimp\_get_map_error_handling_strategies!

        if strategy == strategies.none
          return action!

        if strategy == strategies.log_message
          success, ret_value = pcall(action)
          if success
            return ret_value

          -- In this case ret_value is an error string value
          log.error("Error when calling 'vimp.#{k}'#{get_extra_context(k, args)}: #{ret_value}\n")
          return nil

        if strategy == strategies.log_minimal_user_stack_trace
          success, ret_value = pcall(action)
          if success
            return ret_value

          -- Only show the bottom frame of the stack trace to be less verbose
          -- Usually that's the only part you're interested in anyway
          user_stack_trace = debug.traceback('', 2)
          user_stack_trace_lines = string_util.split(user_stack_trace, '\n')
          if #user_stack_trace_lines > 2
            user_stack_trace = user_stack_trace_lines[1] .. '\n' .. user_stack_trace_lines[2]
          -- In this case ret_value is an error string value
          log.error("Error when calling 'vimp.#{k}'#{get_extra_context(k, args)}: #{ret_value}\n#{user_stack_trace}")
          return nil

        if strategy == strategies.log_user_stack_trace
          success, ret_value = pcall(action)
          if success
            return ret_value

          -- In this case ret_value is an error string value
          log.error("Error when calling 'vimp.#{k}'#{get_extra_context(k, args)}: #{ret_value}\n#{debug.traceback('', 2)}")
          return nil

        if strategy == strategies.log_full_stack_trace
          success, ret_value = xpcall(action, debug.traceback)

          if success
            return ret_value

          -- In this case ret_value is an error string value
          log.error("Error when calling 'vimp.#{k}'#{get_extra_context(k, args)}: #{ret_value}\n")
          return nil

        if strategy == strategies.silent
          success, ret_value = pcall(action)
          if success
            return ret_value
          return nil

        assert.that(strategy == strategies.rethrow_message)

        success, ret_value = pcall(action)

        if success
          return ret_value

        -- In this case ret_value is an error string value
        error("Error when calling 'vimp.#{k}'#{get_extra_context(k, args)}: #{ret_value}")

      rawset(t, k, wrapped_func)
      return wrapped_func

    __newindex: (t, k, v) ->
      setter = _setters[k]

      if setter != nil
        setter(v)
        return

      setter = _setters_deprecated[k]

      if setter != nil
        log.warning("Field 'vimp.#{k}' is deprecated.  Use the snake_case version instead!")
        setter(v)
        return

      error("No member found named 'vimp.#{k}'")
  })
