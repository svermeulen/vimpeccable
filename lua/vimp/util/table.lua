local Table
do
  local _class_0
  local _base_0 = {
    clear = function(table)
      for key in pairs((table)) do
        table[key] = nil
      end
    end,
    getKeys = function(table)
      local _accum_0 = { }
      local _len_0 = 1
      for k, _ in pairs(table) do
        _accum_0[_len_0] = k
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end,
    shallowCopy = function(t)
      local t2 = { }
      for k, v in pairs(t) do
        t2[k] = v
      end
      return t2
    end,
    indexOf = function(list, item)
      for i = 1, #list do
        if item == list[i] then
          return i
        end
      end
      return -1
    end,
    contains = function(list, item)
      return Table.indexOf(list, item) ~= -1
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Table"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Table = _class_0
  return _class_0
end
