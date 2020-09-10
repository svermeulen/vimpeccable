
assert = require("vimp.util.assert")
log = require("vimp.util.log")
tableUtil = require("vimp.util.table")
stringUtil = require("vimp.util.string")

bindMethods = {
  'bind', 'rbind', 'nnoremap', 'inoremap', 'xnoremap',
  'vnoremap', 'onoremap', 'snoremap', 'cnoremap', 'tnoremap',
  'nmap', 'imap', 'xmap', 'vmap', 'omap', 'smap', 'cmap', 'tmap'}

getExtraContext = (member, args) ->
  if tableUtil.contains(bindMethods, member)
    -- Try and add some more context info
    -- If this fails then just ignore
    success, retValue = pcall ->
      modes, options, extraOptions, lhsList, rhs = _vimp\_convertArgs(unpack(args))
      local lhs
      if #lhsList == 1
        lhs = lhsList[1]
      else
        lhs = vim.inspect(lhsList)
      return " when mapping '#{lhs}' for mode '#{modes}'"
    if success
      return retValue

  return ''

-- We assume here that _vimp has been set already
return ->
  _getters = {
    totalNumMaps: _vimp\_getTotalNumMaps,
    mapErrorHandlingStrategies: _vimp\_getMapErrorHandlingStrategies,
    mapErrorHandlingStrategy: _vimp\_getMapErrorHandlingStrategy,
    aliases: _vimp\_getAliases,
    mapsInProgress: _vimp\_getMapsInProgress,
    currentMapInfo: _vimp\_getCurrentMapInfo,
  }
  _setters = {
    mapErrorHandlingStrategy: _vimp\_setMapErrorHandlingStrategy,
    printMinLogLevel: _vimp\_setPrintMinLogLevel,
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
          log.error("Error when calling 'vimp.#{k}'#{getExtraContext(k, args)}: #{retValue}\n")
          return nil

        if strategy == strategies.logMinimalUserStackTrace
          success, retValue = pcall(action)
          if success
            return retValue

          -- Only show the bottom frame of the stack trace to be less verbose
          -- Usually that's the only part you're interested in anyway
          userStackTrace = debug.traceback('', 2)
          userStackTraceLines = stringUtil.split(userStackTrace, '\n')
          if #userStackTraceLines > 2
            userStackTrace = userStackTraceLines[1] .. '\n' .. userStackTraceLines[2]
          -- In this case retValue is an error string value
          log.error("Error when calling 'vimp.#{k}'#{getExtraContext(k, args)}: #{retValue}\n#{userStackTrace}")
          return nil

        if strategy == strategies.logUserStackTrace
          success, retValue = pcall(action)
          if success
            return retValue

          -- In this case retValue is an error string value
          log.error("Error when calling 'vimp.#{k}'#{getExtraContext(k, args)}: #{retValue}\n#{debug.traceback('', 2)}")
          return nil

        if strategy == strategies.logFullStackTrace
          success, retValue = xpcall(action, debug.traceback)

          if success
            return retValue

          -- In this case retValue is an error string value
          log.error("Error when calling 'vimp.#{k}'#{getExtraContext(k, args)}: #{retValue}\n")
          return nil

        if strategy == strategies.silent
          success, retValue = pcall(action)
          if success
            return retValue
          return nil

        assert.that(strategy == strategies.rethrowMessage)

        success, retValue = pcall(action)

        if success
          return retValue

        -- In this case retValue is an error string value
        error("Error when calling 'vimp.#{k}'#{getExtraContext(k, args)}: #{retValue}")

      rawset(t, k, wrappedFunc)
      return wrappedFunc

    __newindex: (t, k, v) ->
      setter = _setters[k]
      if setter != nil
        setter(v)
      else
        error("No member found named 'vimp.#{k}'")
  })
