
assert = require("vimp.util.assert")
log = require("vimp.util.log")

-- We assume here that _vimp has been set already
return ->
  _getters = {
    totalNumMaps: _vimp\_getTotalNumMaps,
    mapErrorHandlingStrategies: _vimp\_getMapErrorHandlingStrategies,
    mapErrorHandlingStrategy: _vimp\_getMapErrorHandlingStrategy,
  }
  _setters = {
    mapErrorHandlingStrategy: _vimp\_setMapErrorHandlingStrategy,
  }

  return setmetatable({}, {
    __index: (t, k) ->
      getter = _getters[k]

      if getter != nil
        return getter!

      func = _vimp[k]

      if func == nil
        error("No member found named 'vimp.#{k}'")

      assert.that(k\sub(1,1) != '_', "Attempted to call private method vimp.#{k}. This is not allowed")

      wrappedFunc = (...) ->
        args = {...}
        action = -> func(_vimp, unpack(args))
        strategy = _vimp\_getMapErrorHandlingStrategy!
        strategies = _vimp\_getMapErrorHandlingStrategies!

        if strategy == strategies.none
          return action!

        if strategy == strategies.logMessage
          success, retValue = pcall(action)
          if success
            return retValue

          -- In this case retValue is an error string value
          log.error("Error when calling 'vimp.#{k}': #{retValue}\n")
          return nil

        if strategy == strategies.logUserStackTrace
          success, retValue = pcall(action)
          if success
            return retValue

          -- In this case retValue is an error string value
          log.error("Error when calling 'vimp.#{k}': #{retValue}\n#{debug.traceback('', 2)}")
          return nil

        if strategy == strategies.logFullStackTrace
          success, retValue = xpcall(action, debug.traceback)

          if success
            return retValue

          -- In this case retValue is an error string value
          log.error("Error when calling 'vimp.#{k}': #{retValue}\n")
          return nil

        assert.that(strategy == strategies.rethrowMessage)

        success, retValue = pcall(action)

        if success
          return retValue

        -- In this case retValue is an error string value
        error("Error when calling 'vimp.#{k}': #{retValue}")

      rawset(t, k, wrappedFunc)
      return wrappedFunc

    __newindex: (t, k, v) ->
      setter = _setters[k]
      if setter != nil
        setter(v)
      else
        error("No member found named 'vimp.#{k}'")
  })
