require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local TestKeys = '<F4>'
local Tester
do
  local _class_0
  local _base_0 = {
    _execInTemporaryBuffer = function(self, func)
      local startBuffer = vim.api.nvim_get_current_buf()
      local tempBuffer = vim.api.nvim_create_buf(true, false)
      vim.cmd("b " .. tostring(tempBuffer))
      func()
      vim.cmd("b " .. tostring(startBuffer))
      return vim.cmd("bd! " .. tostring(tempBuffer))
    end,
    testForceKillBufferBeforeUnmap = function(self)
      self:_execInTemporaryBuffer(function()
        vimp.nnoremap({
          'buffer'
        }, TestKeys, [[:let g:foo = 5<cr>]])
        return assert.isEqual(vimp.totalNumMaps, 1)
      end)
      return assert.isEqual(vimp.totalNumMaps, 0)
    end,
    testNnoremap = function(self)
      helpers.unlet('foo')
      vimp.nnoremap({
        'buffer'
      }, TestKeys, [[:let g:foo = 5<cr>]])
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      assert.isEqual(vim.g.foo, 5)
      helpers.unlet('foo')
      return self:_execInTemporaryBuffer(function()
        helpers.rinput(TestKeys)
        return assert.isEqual(vim.g.foo, nil)
      end)
    end,
    testInoremap = function(self)
      vimp.inoremap({
        'buffer'
      }, TestKeys, 'foo')
      helpers.rinput("i" .. tostring(TestKeys))
      assert.isEqual(helpers.getLine(), 'foo')
      return self:_execInTemporaryBuffer(function()
        helpers.rinput(TestKeys)
        return assert.isEqual(helpers.getLine(), '')
      end)
    end,
    testXnoremap = function(self)
      vimp.xnoremap({
        'buffer'
      }, TestKeys, 'cfoo')
      local setupBuffer
      setupBuffer = function()
        helpers.input("istart middle end<esc>")
        assert.isEqual(helpers.getLine(), 'start middle end')
        helpers.input("Fmviw")
        return helpers.rinput(TestKeys)
      end
      setupBuffer()
      assert.isEqual(helpers.getLine(), 'start foo end')
      return self:_execInTemporaryBuffer(function()
        setupBuffer()
        return assert.isEqual(helpers.getLine(), 'start middle end')
      end)
    end,
    testSnoremap = function(self)
      vimp.snoremap({
        'buffer'
      }, TestKeys, 'foo')
      local setupBuffer
      setupBuffer = function()
        helpers.input("istart mid end<esc>")
        assert.isEqual(helpers.getLine(), 'start mid end')
        helpers.input("Fmgh<right><right>")
        return helpers.rinput(TestKeys)
      end
      setupBuffer()
      assert.isEqual(helpers.getLine(), 'start foo end')
      return self:_execInTemporaryBuffer(function()
        setupBuffer()
        return assert.isEqual(helpers.getLine(), 'start mid end')
      end)
    end,
    testCnoremap = function(self)
      vimp.cnoremap({
        'buffer'
      }, TestKeys, 'foo')
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
      assert.isEqual(vim.g.foo, 'foo')
      return self:_execInTemporaryBuffer(function()
        helpers.unlet('foo')
        helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
        return assert.isEqual(vim.g.foo, TestKeys)
      end)
    end,
    testOnoremap = function(self)
      vimp.onoremap({
        'buffer'
      }, TestKeys, 'aw')
      local setup
      setup = function()
        helpers.input("istart mid end<esc>Fm")
        return helpers.rinput("d" .. tostring(TestKeys))
      end
      setup()
      assert.isEqual(helpers.getLine(), 'start end')
      return self:_execInTemporaryBuffer(function()
        setup()
        return assert.isEqual(helpers.getLine(), 'start mid end')
      end)
    end,
    testNmap = function(self)
      helpers.unlet('foo')
      vimp.nmap({
        'buffer'
      }, TestKeys, [[:let g:foo = 5<cr>]])
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      assert.isEqual(vim.g.foo, 5)
      helpers.unlet('foo')
      return self:_execInTemporaryBuffer(function()
        helpers.rinput(TestKeys)
        return assert.isEqual(vim.g.foo, nil)
      end)
    end,
    testImap = function(self)
      vimp.imap({
        'buffer'
      }, TestKeys, 'foo')
      helpers.rinput("i" .. tostring(TestKeys))
      assert.isEqual(helpers.getLine(), 'foo')
      return self:_execInTemporaryBuffer(function()
        helpers.rinput("i" .. tostring(TestKeys) .. "<esc>")
        return assert.isEqual(helpers.getLine(), TestKeys)
      end)
    end,
    testXmap = function(self)
      vimp.xmap({
        'buffer'
      }, TestKeys, 'cfoo')
      local setup
      setup = function()
        helpers.input("istart middle end<esc>")
        assert.isEqual(helpers.getLine(), 'start middle end')
        helpers.input("Fmviw")
        return helpers.rinput(TestKeys)
      end
      setup()
      assert.isEqual(helpers.getLine(), 'start foo end')
      return self:_execInTemporaryBuffer(function()
        setup()
        return assert.isEqual(helpers.getLine(), "start middle end")
      end)
    end,
    testSmap = function(self)
      vimp.smap({
        'buffer'
      }, TestKeys, 'foo')
      local setup
      setup = function()
        helpers.input("istart mid end<esc>")
        assert.isEqual(helpers.getLine(), 'start mid end')
        helpers.input("Fmgh<right><right>")
        return helpers.rinput(TestKeys)
      end
      setup()
      assert.isEqual(helpers.getLine(), 'start foo end')
      return self:_execInTemporaryBuffer(function()
        setup()
        return assert.isEqual(helpers.getLine(), 'start mid end')
      end)
    end,
    testCmap = function(self)
      vimp.cmap({
        'buffer'
      }, TestKeys, 'foo')
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
      assert.isEqual(vim.g.foo, 'foo')
      return self:_execInTemporaryBuffer(function()
        helpers.unlet('foo')
        helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
        return assert.isEqual(vim.g.foo, TestKeys)
      end)
    end,
    testOmap = function(self)
      vimp.omap({
        'buffer'
      }, TestKeys, 'iw')
      helpers.input("istart mid end<esc>Fm")
      helpers.rinput("d" .. tostring(TestKeys))
      assert.isEqual(helpers.getLine(), 'start  end')
      return self:_execInTemporaryBuffer(function()
        helpers.input("istart mid end<esc>Fm")
        helpers.rinput("d" .. tostring(TestKeys))
        return assert.isEqual(helpers.getLine(), 'start mid end')
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
