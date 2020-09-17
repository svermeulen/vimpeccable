require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local TestKeys = '<f4>'
local Tester
do
  local _class_0
  local _base_0 = {
    test_duplicates_are_not_allowed_by_default = function(self)
      helpers.unlet('foo')
      vimp.nnoremap(TestKeys, [[:let g:foo = 5<cr>]])
      return assert.throws('duplicate mapping', function()
        return vimp.nnoremap(TestKeys, [[:let g:foo = 2<cr>]])
      end)
    end,
    test_override_option = function(self)
      helpers.unlet('foo')
      vimp.nnoremap(TestKeys, [[:let g:foo = 5<cr>]])
      vimp.nnoremap({
        'override'
      }, TestKeys, [[:let g:foo = 2<cr>]])
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      return assert.is_equal(vim.g.foo, 2)
    end,
    test_conflict_with_vim_map1 = function(self)
      helpers.unlet('foo')
      vim.cmd("nnoremap " .. tostring(TestKeys) .. " :<c-u>let g:foo = 2<cr>")
      assert.throws('mapping already exists', function()
        return vimp.nnoremap(TestKeys, [[:let g:foo = 3<cr>]])
      end)
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      assert.is_equal(vim.g.foo, 2)
      return vim.cmd("nunmap <f4>")
    end,
    test_conflict_with_vim_map2 = function(self)
      helpers.unlet('foo')
      vim.cmd("nnoremap " .. tostring(TestKeys) .. " :<c-u>let g:foo = 2<cr>")
      vimp.nnoremap({
        'override'
      }, TestKeys, [[:let g:foo = 3<cr>]])
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      return assert.is_equal(vim.g.foo, 3)
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
