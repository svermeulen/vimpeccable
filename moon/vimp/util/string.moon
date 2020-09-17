
class String
  startsWith: (value, prefix) ->
    value\sub(1, #prefix) == prefix

  ends_with: (value, suffix) ->
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

  char_at: (value, index) ->
    return value\sub(index, index)

  _add_escape_chars: (value) ->
    -- gsub is not ideal in cases where we want to do a literal
    -- replace, so to do this just escape all special characters with '%'
    value = value\gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
    -- Note that we don't put this all in the return statement to avoid
    -- forwarding the multiple return values causing subtle errors
    return value

  index_of: (haystack, needle) ->
    result = haystack\find(String._add_escape_chars(needle))
    return result

  replace: (value, old, new) ->
    return value\gsub(String._add_escape_chars(old), new)

