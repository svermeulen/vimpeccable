require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local TestKeys = '<f4>'
local Tester
do
  local _class_0
  local _base_0 = {
    testDuplicatesAreNotAllowedByDefault = function(self)
      helpers.unlet('foo')
      vimp.nnoremap(TestKeys, [[:let g:foo = 5<cr>]])
      return assert.throws('duplicate mapping', function()
        return vimp.nnoremap(TestKeys, [[:let g:foo = 2<cr>]])
      end)
    end,
    testOverrideOption = function(self)
      helpers.unlet('foo')
      vimp.nnoremap(TestKeys, [[:let g:foo = 5<cr>]])
      vimp.nnoremap({
        'override'
      }, TestKeys, [[:let g:foo = 2<cr>]])
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      return assert.isEqual(vim.g.foo, 2)
    end,
    testConflictWithVimMap1 = function(self)
      helpers.unlet('foo')
      vim.cmd("nnoremap " .. tostring(TestKeys) .. " :<c-u>let g:foo = 2<cr>")
      assert.throws('mapping already exists', function()
        return vimp.nnoremap(TestKeys, [[:let g:foo = 3<cr>]])
      end)
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      assert.isEqual(vim.g.foo, 2)
      return vim.cmd("nunmap <f4>")
    end,
    testConflictWithVimMap2 = function(self)
      helpers.unlet('foo')
      vim.cmd("nnoremap " .. tostring(TestKeys) .. " :<c-u>let g:foo = 2<cr>")
      vimp.nnoremap({
        'override'
      }, TestKeys, [[:let g:foo = 3<cr>]])
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      return assert.isEqual(vim.g.foo, 3)
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
