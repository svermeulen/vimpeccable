local assert
do
  local _class_0
  local _base_0 = {
    that = function(condition, message)
      if not condition then
        if message then
          return error("Assert hit! " .. tostring(message))
        else
          return assert.throw()
        end
      end
    end,
    is_class_instance = function(instance, class_table)
      return assert.is_equal(instance.__class, class_table)
    end,
    throw = function()
      return error("Assert hit!")
    end,
    throws = function(error_pattern, action)
      local ok, error_str = pcall(action)
      assert.that(not ok, 'Expected exception but instead nothing was thrown')
      return assert.that(error_str:find(error_pattern) ~= nil, "Unexpected error message!  Expected '" .. tostring(error_pattern) .. "' but found:\n" .. tostring(error_str))
    end,
    is_equal = function(left, right)
      return assert.that(left == right, "Expected '" .. tostring(left) .. "' to be equal to '" .. tostring(right) .. "'")
    end,
    is_not_equal = function(left, right)
      return assert.that(left ~= right, "Expected '" .. tostring(left) .. "' to not be equal to '" .. tostring(right) .. "'")
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "assert"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  assert = _class_0
  return _class_0
end
