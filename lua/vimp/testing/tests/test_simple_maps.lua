require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local TestKeys = '<f4>'
local Tester
do
  local _class_0
  local _base_0 = {
    testNnoremap = function(self)
      helpers.unlet('foo')
      vimp.nnoremap(TestKeys, [[:let g:foo = 5<cr>]])
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      return assert.isEqual(vim.g.foo, 5)
    end,
    testInoremap = function(self)
      vimp.inoremap(TestKeys, 'foo')
      helpers.rinput("i" .. tostring(TestKeys))
      return assert.isEqual(helpers.getLine(), 'foo')
    end,
    testXnoremap = function(self)
      vimp.xnoremap(TestKeys, 'cfoo')
      helpers.input("istart middle end<esc>")
      assert.isEqual(helpers.getLine(), 'start middle end')
      helpers.input("Fmviw")
      helpers.rinput(TestKeys)
      return assert.isEqual(helpers.getLine(), 'start foo end')
    end,
    testSnoremap = function(self)
      vimp.snoremap(TestKeys, 'foo')
      helpers.input("istart mid end<esc>")
      assert.isEqual(helpers.getLine(), 'start mid end')
      helpers.input("Fmgh<right><right>")
      helpers.rinput(TestKeys)
      return assert.isEqual(helpers.getLine(), 'start foo end')
    end,
    testCnoremap = function(self)
      vimp.cnoremap(TestKeys, 'foo')
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
      return assert.isEqual(vim.g.foo, 'foo')
    end,
    testOnoremap = function(self)
      vimp.onoremap(TestKeys, 'aw')
      helpers.input("istart mid end<esc>Fm")
      helpers.rinput("d" .. tostring(TestKeys))
      return assert.isEqual(helpers.getLine(), 'start end')
    end,
    testNmap = function(self)
      helpers.unlet('foo')
      vimp.nmap(TestKeys, [[:let g:foo = 5<cr>]])
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      return assert.isEqual(vim.g.foo, 5)
    end,
    testImap = function(self)
      vimp.imap(TestKeys, 'foo')
      helpers.rinput("i" .. tostring(TestKeys))
      return assert.isEqual(helpers.getLine(), 'foo')
    end,
    testXmap = function(self)
      vimp.xmap(TestKeys, 'cfoo')
      helpers.input("istart middle end<esc>")
      assert.isEqual(helpers.getLine(), 'start middle end')
      helpers.input("Fmviw")
      helpers.rinput(TestKeys)
      return assert.isEqual(helpers.getLine(), 'start foo end')
    end,
    testSmap = function(self)
      vimp.smap(TestKeys, 'foo')
      helpers.input("istart mid end<esc>")
      assert.isEqual(helpers.getLine(), 'start mid end')
      helpers.input("Fmgh<right><right>")
      helpers.rinput(TestKeys)
      return assert.isEqual(helpers.getLine(), 'start foo end')
    end,
    testCmap = function(self)
      vimp.cmap(TestKeys, 'foo')
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
      return assert.isEqual(vim.g.foo, 'foo')
    end,
    testOmap = function(self)
      vimp.omap(TestKeys, 'iw')
      helpers.input("istart mid end<esc>Fm")
      helpers.rinput("d" .. tostring(TestKeys))
      return assert.isEqual(helpers.getLine(), 'start  end')
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
