
class String
  startsWith: (value, prefix) ->
    value\sub(1, #prefix) == prefix

  endsWith: (value, suffix) ->
    value\sub(#value + 1 - #suffix) == suffix

  split: (value, sep) ->
    [x for x in string.gmatch(value, "([^#{sep}]+)")]

  join: (separator, list) ->
    result = ''
    for item in *list
      if #result != 0
        result ..= separator
      result ..= tostring(item)
    return result

  charAt: (value, index) ->
    return value\sub(index, index)

  _addEscapeChars: (value) ->
    -- gsub is not ideal in cases where we want to do a literal
    -- replace, so to do this just escape all special characters with '%'
    value = value\gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
    -- Note that we don't put this all in the return statement to avoid
    -- forwarding the multiple return values causing subtle errors
    return value

  indexOf: (haystack, needle) ->
    result = haystack\find(String._addEscapeChars(needle))
    return result

  replace: (value, old, new) ->
    return value\gsub(String._addEscapeChars(old), new)

