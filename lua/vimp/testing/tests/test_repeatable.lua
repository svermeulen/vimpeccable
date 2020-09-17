require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local TestKeys = '<space>t7<f4>'
local TestKeys2 = ',<space>t9<f5>'
local Tester
do
  local _class_0
  local _base_0 = {
    test_key_map = function(self)
      vimp.nnoremap({
        'repeatable'
      }, TestKeys, 'dlldl')
      helpers.set_lines({
        "foo bar"
      })
      helpers.input("0w")
      helpers.rinput(TestKeys)
      assert.is_equal(helpers.get_line(), 'foo a')
      helpers.input("0")
      helpers.rinput('.')
      return assert.is_equal(helpers.get_line(), 'o a')
    end,
    test_key_map_recursive = function(self)
      vimp.nnoremap(TestKeys2, 'dlldl')
      vimp.nmap({
        'repeatable'
      }, TestKeys, TestKeys2)
      helpers.set_lines({
        "foo bar"
      })
      helpers.input("0w")
      helpers.rinput(TestKeys)
      assert.is_equal(helpers.get_line(), 'foo a')
      helpers.input("0")
      helpers.rinput('.')
      return assert.is_equal(helpers.get_line(), 'o a')
    end,
    test_wrong_mode = function(self)
      return assert.throws("currently only supported", function()
        return vimp.inoremap({
          'repeatable'
        }, TestKeys, 'foo')
      end)
    end,
    test_lua_func = function(self)
      vimp.nnoremap({
        'repeatable'
      }, TestKeys, function()
        return vim.cmd('normal! dlldl')
      end)
      helpers.set_lines({
        "foo bar"
      })
      helpers.input("0w")
      helpers.rinput(TestKeys)
      assert.is_equal(helpers.get_line(), 'foo a')
      helpers.input("0")
      helpers.rinput('.')
      return assert.is_equal(helpers.get_line(), 'o a')
    end,
    test_lua_func_expr = function(self)
      return assert.throws("currently not supported", function()
        return vimp.nnoremap({
          'repeatable',
          'expr'
        }, TestKeys, function()
          return 'dlldl'
        end)
      end)
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
