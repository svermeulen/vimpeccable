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
    testMultipleLhs = function(self)
      helpers.unlet('foo')
      vimp.nnoremap({
        TestKeys1,
        TestKeys2
      }, [[:let g:foo = 5<cr>]])
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys1)
      assert.isEqual(vim.g.foo, 5)
      helpers.unlet('foo')
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys2)
      return assert.isEqual(vim.g.foo, 5)
    end,
    testMultipleModes = function(self)
      vimp.bind('nx', {
        TestKeys1,
        TestKeys2
      }, '<right>')
      helpers.setLines({
        "abc def"
      })
      helpers.input('0')
      helpers.rinput(TestKeys1)
      assert.isEqual(helpers.getCursorCharacter(), 'b')
      helpers.rinput(TestKeys2)
      assert.isEqual(helpers.getCursorCharacter(), 'c')
      helpers.input("0v")
      helpers.rinput(TestKeys1)
      helpers.rinput(TestKeys2)
      helpers.input("d")
      return assert.isEqual(helpers.getLine(), ' def')
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
