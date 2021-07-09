local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local table_util = require("vimp.util.table")
local string_util = require("vimp.util.string")
local bind_methods = {
  'bind',
  'rbind',
  'nnoremap',
  'inoremap',
  'xnoremap',
  'vnoremap',
  'onoremap',
  'snoremap',
  'cnoremap',
  'tnoremap',
  'nmap',
  'imap',
  'xmap',
  'vmap',
  'omap',
  'smap',
  'cmap',
  'tmap'
}
local get_extra_context
get_extra_context = function(member, args)
  if table_util.contains(bind_methods, member) then
    local success, ret_value = pcall(function()
      local modes, options, extra_options, lhs_list, rhs = _vimp:_convert_args(unpack(args))
      local lhs
      if #lhs_list == 1 then
        lhs = lhs_list[1]
      else
        lhs = vim.inspect(lhs_list)
      end
      return " when mapping '" .. tostring(lhs) .. "' for mode '" .. tostring(modes) .. "'"
    end)
    if success then
      return ret_value
    end
  end
  return ''
end
return function()
  local _getters = {
    total_num_maps = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_total_num_maps
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    map_error_handling_strategies = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_map_error_handling_strategies
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    map_error_handling_strategy = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_map_error_handling_strategy
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    aliases = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_aliases
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    maps_in_progress = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_maps_in_progress
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    current_map_info = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_current_map_info
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)()
  }
  local _setters = {
    map_error_handling_strategy = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._set_map_error_handling_strategy
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    print_min_log_level = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._set_print_min_log_level
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    map_context_provider = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._set_map_context_provider
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)()
  }
  local _getters_deprecated = {
    totalNumMaps = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_total_num_maps
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    mapErrorHandlingStrategies = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_map_error_handling_strategies
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    mapErrorHandlingStrategy = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_map_error_handling_strategy
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    mapsInProgress = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_maps_in_progress
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    currentMapInfo = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._get_current_map_info
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)()
  }
  local _setters_deprecated = {
    mapErrorHandlingStrategy = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._set_map_error_handling_strategy
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    printMinLogLevel = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._set_print_min_log_level
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)()
  }
  return setmetatable({ }, {
    __index = function(t, k)
      local getter = _getters[k]
      if getter ~= nil then
        return getter()
      end
      getter = _getters_deprecated[k]
      if getter ~= nil then
        log.warning("Field 'vimp." .. tostring(k) .. "' is deprecated.  Use the snake_case version instead!")
        return getterDeprecated()
      end
      local func = _vimp[k]
      if func == nil then
        error("No member found named 'vimp." .. tostring(k) .. "'")
      end
      assert.that(k:sub(1, 1) ~= '_', "Attempted to call private method vimp." .. tostring(k) .. ". This is not allowed")
      local wrapped_func
      wrapped_func = function(...)
        local args = {
          ...
        }
        local action
        action = function()
          return func(_vimp, unpack(args))
        end
        local strategy = _vimp:_get_map_error_handling_strategy()
        local strategies = _vimp:_get_map_error_handling_strategies()
        if strategy == strategies.none then
          return action()
        end
        if strategy == strategies.log_message then
          local success, ret_value = pcall(action)
          if success then
            return ret_value
          end
          log.error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(get_extra_context(k, args)) .. ": " .. tostring(ret_value) .. "\n")
          return nil
        end
        if strategy == strategies.log_minimal_user_stack_trace then
          local success, ret_value = pcall(action)
          if success then
            return ret_value
          end
          local user_stack_trace = debug.traceback('', 2)
          local user_stack_trace_lines = string_util.split(user_stack_trace, '\n')
          if #user_stack_trace_lines > 2 then
            user_stack_trace = user_stack_trace_lines[1] .. '\n' .. user_stack_trace_lines[2]
          end
          log.error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(get_extra_context(k, args)) .. ": " .. tostring(ret_value) .. "\n" .. tostring(user_stack_trace))
          return nil
        end
        if strategy == strategies.log_user_stack_trace then
          local success, ret_value = pcall(action)
          if success then
            return ret_value
          end
          log.error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(get_extra_context(k, args)) .. ": " .. tostring(ret_value) .. "\n" .. tostring(debug.traceback('', 2)))
          return nil
        end
        if strategy == strategies.log_full_stack_trace then
          local success, ret_value = xpcall(action, debug.traceback)
          if success then
            return ret_value
          end
          log.error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(get_extra_context(k, args)) .. ": " .. tostring(ret_value) .. "\n")
          return nil
        end
        if strategy == strategies.silent then
          local success, ret_value = pcall(action)
          if success then
            return ret_value
          end
          return nil
        end
        assert.that(strategy == strategies.rethrow_message)
        local success, ret_value = pcall(action)
        if success then
          return ret_value
        end
        return error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(get_extra_context(k, args)) .. ": " .. tostring(ret_value))
      end
      rawset(t, k, wrapped_func)
      return wrapped_func
    end,
    __newindex = function(t, k, v)
      local setter = _setters[k]
      if setter ~= nil then
        setter(v)
        return 
      end
      setter = _setters_deprecated[k]
      if setter ~= nil then
        log.warning("Field 'vimp." .. tostring(k) .. "' is deprecated.  Use the snake_case version instead!")
        setter(v)
        return 
      end
      return error("No member found named 'vimp." .. tostring(k) .. "'")
    end
  })
end
