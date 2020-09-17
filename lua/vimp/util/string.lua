local String
do
  local _class_0
  local _base_0 = {
    startsWith = function(value, prefix)
      return value:sub(1, #prefix) == prefix
    end,
    ends_with = function(value, suffix)
      return value:sub(#value + 1 - #suffix) == suffix
    end,
    split = function(value, sep)
      local _accum_0 = { }
      local _len_0 = 1
      for x in string.gmatch(value, "([^" .. tostring(sep) .. "]+)") do
        _accum_0[_len_0] = x
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end,
    join = function(separator, list)
      local result = ''
      for _index_0 = 1, #list do
        local item = list[_index_0]
        if #result ~= 0 then
          result = result .. separator
        end
        result = result .. tostring(item)
      end
      return result
    end,
    char_at = function(value, index)
      return value:sub(index, index)
    end,
    _add_escape_chars = function(value)
      value = value:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
      return value
    end,
    index_of = function(haystack, needle)
      local result = haystack:find(String._add_escape_chars(needle))
      return result
    end,
    replace = function(value, old, new)
      return value:gsub(String._add_escape_chars(old), new)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "String"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  String = _class_0
  return _class_0
end
