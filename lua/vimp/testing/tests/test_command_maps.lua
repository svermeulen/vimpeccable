require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local Tester
do
  local _class_0
  local _base_0 = {
    test_zero_args = function(self)
      local received = false
      vimp.map_command("Foo", function()
        received = true
      end)
      assert.that(not received)
      vim.cmd("Foo")
      return assert.that(received)
    end,
    test_one_args = function(self)
      local received = nil
      vimp.map_command("Foo", function(val)
        received = val
      end)
      assert.that(received == nil)
      vim.cmd("Foo 5")
      assert.is_equal(received, '5')
      vim.cmd("Foo foo bar qux")
      assert.is_equal(received, "foo bar qux")
      return assert.throws("Argument required", function()
        return vim.cmd("Foo")
      end)
    end,
    test_two_args = function(self)
      local received1 = nil
      local received2 = nil
      vimp.map_command("Foo", function(val1, val2)
        received1 = val1
        received2 = val2
      end)
      assert.that(received2 == nil)
      assert.that(received1 == nil)
      vim.cmd("Foo 5")
      assert.is_equal(received1, '5')
      assert.is_equal(received2, nil)
      vim.cmd("Foo")
      assert.is_equal(received1, nil)
      assert.is_equal(received2, nil)
      vim.cmd("Foo first second")
      assert.is_equal(received1, 'first')
      assert.is_equal(received2, 'second')
      vim.cmd("Foo first second third")
      assert.is_equal(received1, 'first')
      return assert.is_equal(received2, 'second')
    end,
    test_var_args = function(self)
      local received = nil
      vimp.map_command("Foo", function(...)
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
      return helpers.assert_same_contents(received, {
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
