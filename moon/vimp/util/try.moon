
onError = (errorObj) ->
  debug.traceback(errorObj, 2)

return (t) ->
  success, retValue = xpcall(t.do, onError)

  if success
    t.finally! if t.finally
    return retValue

  if not t.catch
    t.finally! if t.finally
    -- retValue here will be an Exception object
    error(retValue, 2)

  success, retValue = xpcall((-> t.catch(retValue)), onError)
  t.finally! if t.finally

  if success
    return retValue

  -- retValue here will be an Exception object
  error(retValue, 2)


