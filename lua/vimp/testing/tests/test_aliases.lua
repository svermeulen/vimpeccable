require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local TestKeys1 = '<F4>'
local TestKeys2 = '<F5>'
local Tester
do
  local _class_0
  local _base_0 = {
    test_simple_alias = function(self)
      helpers.unlet('foo')
      vimp.add_alias(TestKeys1, TestKeys2)
      vimp.nnoremap(TestKeys1, [[:let g:foo = 5<cr>]])
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys2)
      assert.is_equal(vim.g.foo, 5)
      helpers.unlet('foo')
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys1)
      return assert.is_equal(vim.g.foo, nil)
    end,
    test_multiple_aliases = function(self)
      helpers.unlet('foo')
      vimp.add_alias('<d-g>', TestKeys1)
      vimp.add_alias('<d-e>', TestKeys2)
      vimp.nnoremap('<d-g><d-e>', [[:let g:foo = 5<cr>]])
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys1)
      helpers.input('<esc>')
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys2)
      helpers.input('<esc>')
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(tostring(TestKeys1) .. tostring(TestKeys2))
      return assert.is_equal(vim.g.foo, 5)
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
