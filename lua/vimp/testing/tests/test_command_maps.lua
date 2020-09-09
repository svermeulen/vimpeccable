require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local Tester
do
  local _class_0
  local _base_0 = {
    testZeroArgs = function(self)
      local received = false
      vimp.mapCommand("Foo", function()
        received = true
      end)
      assert.that(not received)
      vim.cmd("Foo")
      return assert.that(received)
    end,
    testOneArgs = function(self)
      local received = nil
      vimp.mapCommand("Foo", function(val)
        received = val
      end)
      assert.that(received == nil)
      vim.cmd("Foo 5")
      assert.isEqual(received, '5')
      vim.cmd("Foo foo bar qux")
      assert.isEqual(received, "foo bar qux")
      return assert.throws("Argument required", function()
        return vim.cmd("Foo")
      end)
    end,
    testTwoArgs = function(self)
      local received1 = nil
      local received2 = nil
      vimp.mapCommand("Foo", function(val1, val2)
        received1 = val1
        received2 = val2
      end)
      assert.that(received2 == nil)
      assert.that(received1 == nil)
      vim.cmd("Foo 5")
      assert.isEqual(received1, '5')
      assert.isEqual(received2, nil)
      vim.cmd("Foo")
      assert.isEqual(received1, nil)
      assert.isEqual(received2, nil)
      vim.cmd("Foo first second")
      assert.isEqual(received1, 'first')
      assert.isEqual(received2, 'second')
      vim.cmd("Foo first second third")
      assert.isEqual(received1, 'first')
      return assert.isEqual(received2, 'second')
    end,
    testVarArgs = function(self)
      local received = nil
      vimp.mapCommand("Foo", function(...)
        received = {
          ...
        }
      end)
      assert.that(received == nil)
      vim.cmd("Foo")
      assert.that(#received == 0)
      vim.cmd("Foo first")
      assert.that(#received == 1)
      assert.that(received[1] == "first")
      vim.cmd("Foo first second third")
      assert.that(#received == 3)
      return helpers.assertSameContents(received, {
        'first',
        'second',
        'third'
      })
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Tester"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Tester = _class_0
  return _class_0
end
