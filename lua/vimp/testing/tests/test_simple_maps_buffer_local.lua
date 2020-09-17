require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local TestKeys = '<F4>'
local Tester
do
  local _class_0
  local _base_0 = {
    _exec_in_temporary_buffer = function(self, func)
      local startBuffer = vim.api.nvim_get_current_buf()
      local tempBuffer = vim.api.nvim_create_buf(true, false)
      vim.cmd("b " .. tostring(tempBuffer))
      func()
      vim.cmd("b " .. tostring(startBuffer))
      return vim.cmd("bd! " .. tostring(tempBuffer))
    end,
    test_force_kill_buffer_before_unmap = function(self)
      self:_exec_in_temporary_buffer(function()
        vimp.nnoremap({
          'buffer'
        }, TestKeys, [[:let g:foo = 5<cr>]])
        return assert.is_equal(vimp.total_num_maps, 1)
      end)
      return assert.is_equal(vimp.total_num_maps, 0)
    end,
    test_nnoremap = function(self)
      helpers.unlet('foo')
      vimp.nnoremap({
        'buffer'
      }, TestKeys, [[:let g:foo = 5<cr>]])
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      assert.is_equal(vim.g.foo, 5)
      helpers.unlet('foo')
      return self:_exec_in_temporary_buffer(function()
        helpers.rinput(TestKeys)
        return assert.is_equal(vim.g.foo, nil)
      end)
    end,
    test_inoremap = function(self)
      vimp.inoremap({
        'buffer'
      }, TestKeys, 'foo')
      helpers.rinput("i" .. tostring(TestKeys))
      assert.is_equal(helpers.get_line(), 'foo')
      return self:_exec_in_temporary_buffer(function()
        helpers.rinput(TestKeys)
        return assert.is_equal(helpers.get_line(), '')
      end)
    end,
    test_xnoremap = function(self)
      vimp.xnoremap({
        'buffer'
      }, TestKeys, 'cfoo')
      local setupBuffer
      setupBuffer = function()
        helpers.input("istart middle end<esc>")
        assert.is_equal(helpers.get_line(), 'start middle end')
        helpers.input("Fmviw")
        return helpers.rinput(TestKeys)
      end
      setupBuffer()
      assert.is_equal(helpers.get_line(), 'start foo end')
      return self:_exec_in_temporary_buffer(function()
        setupBuffer()
        return assert.is_equal(helpers.get_line(), 'start middle end')
      end)
    end,
    test_snoremap = function(self)
      vimp.snoremap({
        'buffer'
      }, TestKeys, 'foo')
      local setupBuffer
      setupBuffer = function()
        helpers.input("istart mid end<esc>")
        assert.is_equal(helpers.get_line(), 'start mid end')
        helpers.input("Fmgh<right><right>")
        return helpers.rinput(TestKeys)
      end
      setupBuffer()
      assert.is_equal(helpers.get_line(), 'start foo end')
      return self:_exec_in_temporary_buffer(function()
        setupBuffer()
        return assert.is_equal(helpers.get_line(), 'start mid end')
      end)
    end,
    test_cnoremap = function(self)
      vimp.cnoremap({
        'buffer'
      }, TestKeys, 'foo')
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
      assert.is_equal(vim.g.foo, 'foo')
      return self:_exec_in_temporary_buffer(function()
        helpers.unlet('foo')
        helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
        return assert.is_equal(vim.g.foo, TestKeys)
      end)
    end,
    test_onoremap = function(self)
      vimp.onoremap({
        'buffer'
      }, TestKeys, 'aw')
      local setup
      setup = function()
        helpers.input("istart mid end<esc>Fm")
        return helpers.rinput("d" .. tostring(TestKeys))
      end
      setup()
      assert.is_equal(helpers.get_line(), 'start end')
      return self:_exec_in_temporary_buffer(function()
        setup()
        return assert.is_equal(helpers.get_line(), 'start mid end')
      end)
    end,
    test_nmap = function(self)
      helpers.unlet('foo')
      vimp.nmap({
        'buffer'
      }, TestKeys, [[:let g:foo = 5<cr>]])
      assert.is_equal(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      assert.is_equal(vim.g.foo, 5)
      helpers.unlet('foo')
      return self:_exec_in_temporary_buffer(function()
        helpers.rinput(TestKeys)
        return assert.is_equal(vim.g.foo, nil)
      end)
    end,
    test_imap = function(self)
      vimp.imap({
        'buffer'
      }, TestKeys, 'foo')
      helpers.rinput("i" .. tostring(TestKeys))
      assert.is_equal(helpers.get_line(), 'foo')
      return self:_exec_in_temporary_buffer(function()
        helpers.rinput("i" .. tostring(TestKeys) .. "<esc>")
        return assert.is_equal(helpers.get_line(), TestKeys)
      end)
    end,
    test_xmap = function(self)
      vimp.xmap({
        'buffer'
      }, TestKeys, 'cfoo')
      local setup
      setup = function()
        helpers.input("istart middle end<esc>")
        assert.is_equal(helpers.get_line(), 'start middle end')
        helpers.input("Fmviw")
        return helpers.rinput(TestKeys)
      end
      setup()
      assert.is_equal(helpers.get_line(), 'start foo end')
      return self:_exec_in_temporary_buffer(function()
        setup()
        return assert.is_equal(helpers.get_line(), "start middle end")
      end)
    end,
    test_smap = function(self)
      vimp.smap({
        'buffer'
      }, TestKeys, 'foo')
      local setup
      setup = function()
        helpers.input("istart mid end<esc>")
        assert.is_equal(helpers.get_line(), 'start mid end')
        helpers.input("Fmgh<right><right>")
        return helpers.rinput(TestKeys)
      end
      setup()
      assert.is_equal(helpers.get_line(), 'start foo end')
      return self:_exec_in_temporary_buffer(function()
        setup()
        return assert.is_equal(helpers.get_line(), 'start mid end')
      end)
    end,
    test_cmap = function(self)
      vimp.cmap({
        'buffer'
      }, TestKeys, 'foo')
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
      assert.is_equal(vim.g.foo, 'foo')
      return self:_exec_in_temporary_buffer(function()
        helpers.unlet('foo')
        helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
        return assert.is_equal(vim.g.foo, TestKeys)
      end)
    end,
    test_omap = function(self)
      vimp.omap({
        'buffer'
      }, TestKeys, 'iw')
      helpers.input("istart mid end<esc>Fm")
      helpers.rinput("d" .. tostring(TestKeys))
      assert.is_equal(helpers.get_line(), 'start  end')
      return self:_exec_in_temporary_buffer(function()
        helpers.input("istart mid end<esc>Fm")
        helpers.rinput("d" .. tostring(TestKeys))
        return assert.is_equal(helpers.get_line(), 'start mid end')
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
