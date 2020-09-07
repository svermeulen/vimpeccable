
class String
  startsWith: (value, prefix) ->
    value\sub(1, #prefix) == prefix

  endsWith: (value, suffix) ->
    value\sub(#value + 1 - #suffix) == suffix

  split: (value, sep) ->
    [x for x in string.gmatch(value, "([^#{sep}]+)")]

