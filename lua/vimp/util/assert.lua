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
    isClassInstance = function(instance, classTable)
      return assert.isEqual(instance.__class, classTable)
    end,
    throw = function()
      return error("Assert hit!")
    end,
    throws = function(errorPattern, action)
      local ok, errorStr = pcall(action)
      assert.that(not ok, 'Expected exception but instead nothing was thrown')
      return assert.that(errorStr:find(errorPattern) ~= nil, "Unexpected error message!  Expected '" .. tostring(errorPattern) .. "' but found:\n" .. tostring(errorStr))
    end,
    isEqual = function(left, right)
      return assert.that(left == right, "Expected '" .. tostring(left) .. "' to be equal to '" .. tostring(right) .. "'")
    end,
    isNotEqual = function(left, right)
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
