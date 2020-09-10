local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local tableUtil = require("vimp.util.table")
local stringUtil = require("vimp.util.string")
local bindMethods = {
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
local getExtraContext
getExtraContext = function(member, args)
  if tableUtil.contains(bindMethods, member) then
    local success, retValue = pcall(function()
      local modes, options, extraOptions, lhsList, rhs = _vimp:_convertArgs(unpack(args))
      local lhs
      if #lhsList == 1 then
        lhs = lhsList[1]
      else
        lhs = vim.inspect(lhsList)
      end
      return " when mapping '" .. tostring(lhs) .. "' for mode '" .. tostring(modes) .. "'"
    end)
    if success then
      return retValue
    end
  end
  return ''
end
return function()
  local _getters = {
    totalNumMaps = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._getTotalNumMaps
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    mapErrorHandlingStrategies = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._getMapErrorHandlingStrategies
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    mapErrorHandlingStrategy = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._getMapErrorHandlingStrategy
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    aliases = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._getAliases
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    mapsInProgress = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._getMapsInProgress
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    currentMapInfo = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._getCurrentMapInfo
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)()
  }
  local _setters = {
    mapErrorHandlingStrategy = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._setMapErrorHandlingStrategy
      return function(...)
        return _fn_0(_base_0, ...)
      end
    end)(),
    printMinLogLevel = (function()
      local _base_0 = _vimp
      local _fn_0 = _base_0._setPrintMinLogLevel
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
      local func = _vimp[k]
      if func == nil then
        error("No member found named 'vimp." .. tostring(k) .. "'")
      end
      assert.that(k:sub(1, 1) ~= '_', "Attempted to call private method vimp." .. tostring(k) .. ". This is not allowed")
      local wrappedFunc
      wrappedFunc = function(...)
        local args = {
          ...
        }
        local action
        action = function()
          return func(_vimp, unpack(args))
        end
        local strategy = _vimp:_getMapErrorHandlingStrategy()
        local strategies = _vimp:_getMapErrorHandlingStrategies()
        if strategy == strategies.none then
          return action()
        end
        if strategy == strategies.logMessage then
          local success, retValue = pcall(action)
          if success then
            return retValue
          end
          log.error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(getExtraContext(k, args)) .. ": " .. tostring(retValue) .. "\n")
          return nil
        end
        if strategy == strategies.logMinimalUserStackTrace then
          local success, retValue = pcall(action)
          if success then
            return retValue
          end
          local userStackTrace = debug.traceback('', 2)
          local userStackTraceLines = stringUtil.split(userStackTrace, '\n')
          if #userStackTraceLines > 2 then
            userStackTrace = userStackTraceLines[1] .. '\n' .. userStackTraceLines[2]
          end
          log.error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(getExtraContext(k, args)) .. ": " .. tostring(retValue) .. "\n" .. tostring(userStackTrace))
          return nil
        end
        if strategy == strategies.logUserStackTrace then
          local success, retValue = pcall(action)
          if success then
            return retValue
          end
          log.error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(getExtraContext(k, args)) .. ": " .. tostring(retValue) .. "\n" .. tostring(debug.traceback('', 2)))
          return nil
        end
        if strategy == strategies.logFullStackTrace then
          local success, retValue = xpcall(action, debug.traceback)
          if success then
            return retValue
          end
          log.error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(getExtraContext(k, args)) .. ": " .. tostring(retValue) .. "\n")
          return nil
        end
        if strategy == strategies.silent then
          local success, retValue = pcall(action)
          if success then
            return retValue
          end
          return nil
        end
        assert.that(strategy == strategies.rethrowMessage)
        local success, retValue = pcall(action)
        if success then
          return retValue
        end
        return error("Error when calling 'vimp." .. tostring(k) .. "'" .. tostring(getExtraContext(k, args)) .. ": " .. tostring(retValue))
      end
      rawset(t, k, wrappedFunc)
      return wrappedFunc
    end,
    __newindex = function(t, k, v)
      local setter = _setters[k]
      if setter ~= nil then
        return setter(v)
      else
        return error("No member found named 'vimp." .. tostring(k) .. "'")
      end
    end
  })
end
