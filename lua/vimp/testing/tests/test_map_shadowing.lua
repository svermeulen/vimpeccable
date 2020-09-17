require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local TestKeys1 = '<space>ab'
local TestKeys2 = '<space>abc'
local Tester
do
  local _class_0
  local _base_0 = {
    test_disallows_longer_map = function(self)
      helpers.unlet('foo')
      vimp.nnoremap(TestKeys1, [[:let g:foo = 5<cr>]])
      assert.throws("Map conflict found", function()
        return vimp.nnoremap(TestKeys2, [[:let g:foo = 2<cr>]])
      end)
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys1)
      assert.is_equal(vim.g.foo, 5)
      return assert.is_equal(vimp.total_num_maps, 1)
    end,
    test_override_does_not_work_with_shadows = function(self)
      helpers.unlet('foo')
      vimp.nnoremap({
        'override'
      }, TestKeys1, [[:let g:foo = 5<cr>]])
      assert.throws("Map conflict found", function()
        return vimp.nnoremap(TestKeys2, [[:let g:foo = 2<cr>]])
      end)
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys1)
      assert.is_equal(vim.g.foo, 5)
      return assert.is_equal(vimp.total_num_maps, 1)
    end,
    test_disallows_shorter_map = function(self)
      helpers.unlet('foo')
      vimp.nnoremap(TestKeys2, [[:let g:foo = 5<cr>]])
      assert.throws("Map conflict found", function()
        return vimp.nnoremap(TestKeys1, [[:let g:foo = 2<cr>]])
      end)
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys2)
      assert.is_equal(vim.g.foo, 5)
      return assert.is_equal(vimp.total_num_maps, 1)
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
