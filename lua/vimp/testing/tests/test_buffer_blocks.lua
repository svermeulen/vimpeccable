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
    test_buffer_block = function(self)
      helpers.unlet('foo')
      local startBuffer = vim.api.nvim_get_current_buf()
      local tempBuffer = vim.api.nvim_create_buf(true, false)
      assert.is_equal(startBuffer, vim.api.nvim_get_current_buf())
      vimp.add_buffer_maps(tempBuffer, function()
        vimp.nnoremap(TestKeys1, [[:let g:foo = 5<cr>]])
        return vimp.nnoremap(TestKeys2, [[:let g:foo = 7<cr>]])
      end)
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys1)
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys2)
      assert.is_equal(vim.g.foo, nil)
      vim.cmd("b " .. tostring(tempBuffer))
      helpers.rinput(TestKeys1)
      assert.is_equal(vim.g.foo, 5)
      helpers.rinput(TestKeys2)
      return assert.is_equal(vim.g.foo, 7)
    end,
    test_buffer_block_only_one_at_a_time = function(self)
      local startBuffer = vim.api.nvim_get_current_buf()
      local tempBuffer = vim.api.nvim_create_buf(true, false)
      assert.is_equal(startBuffer, vim.api.nvim_get_current_buf())
      vimp.add_buffer_maps(tempBuffer, function()
        vimp.nnoremap(TestKeys1, [[:let g:foo = 5<cr>]])
        return vimp.add_buffer_maps(startBuffer, function()
          return vimp.nnoremap(TestKeys2, [[:let g:foo = 7<cr>]])
        end)
      end)
      helpers.rinput(TestKeys1)
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
