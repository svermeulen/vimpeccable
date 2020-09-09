require('vimp')
local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local TestKeys = '<F4>'
local TestKeys2 = '<F5>'
local Tester
do
  local _class_0
  local _base_0 = {
    testNnoremap = function(self)
      helpers.unlet('foo')
      vimp.nnoremap({
        'expr'
      }, TestKeys, function()
        return [[:let g:foo = 5<cr>]]
      end)
      assert.isEqual(vim.g.foo, nil)
      helpers.rinput(TestKeys)
      return assert.isEqual(vim.g.foo, 5)
    end,
    testInoremap = function(self)
      vimp.inoremap({
        'expr'
      }, TestKeys, function()
        return 'foo'
      end)
      helpers.rinput("i" .. tostring(TestKeys))
      return assert.isEqual(helpers.getLine(), 'foo')
    end,
    testXnoremap = function(self)
      vimp.xnoremap({
        'expr'
      }, TestKeys, function()
        return 'cfoo'
      end)
      helpers.input("istart middle end<esc>")
      assert.isEqual(helpers.getLine(), 'start middle end')
      helpers.input("Fmviw")
      helpers.rinput(TestKeys)
      return assert.isEqual(helpers.getLine(), 'start foo end')
    end,
    testSnoremap = function(self)
      vimp.snoremap({
        'expr'
      }, TestKeys, function()
        return 'foo'
      end)
      helpers.input("istart mid end<esc>")
      assert.isEqual(helpers.getLine(), 'start mid end')
      helpers.input("Fmgh<right><right>")
      helpers.rinput(TestKeys)
      return assert.isEqual(helpers.getLine(), 'start foo end')
    end,
    testCnoremap = function(self)
      vimp.cnoremap({
        'expr'
      }, TestKeys, function()
        return 'foo'
      end)
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
      return assert.isEqual(vim.g.foo, 'foo')
    end,
    testOnoremap = function(self)
      vimp.onoremap({
        'expr'
      }, TestKeys, function()
        return 'aw'
      end)
      helpers.input("istart mid end<esc>Fm")
      helpers.rinput("d" .. tostring(TestKeys))
      return assert.isEqual(helpers.getLine(), 'start end')
    end,
    testNmap = function(self)
      vimp.nnoremap(TestKeys2, 'diw')
      vimp.nmap({
        'expr'
      }, TestKeys, function()
        return TestKeys2
      end)
      helpers.setLines({
        'foo bar qux'
      })
      helpers.input("0w")
      helpers.rinput(tostring(TestKeys))
      return assert.isEqual(helpers.getLine(), 'foo  qux')
    end,
    testImap = function(self)
      vimp.inoremap(TestKeys2, 'qux')
      vimp.imap({
        'expr'
      }, TestKeys, function()
        return TestKeys2
      end)
      helpers.setLines({
        'foo bar'
      })
      helpers.input("0w")
      helpers.rinput("i" .. tostring(TestKeys) .. "<esc>")
      return assert.isEqual(helpers.getLine(), 'foo quxbar')
    end,
    testXmap = function(self)
      vimp.xnoremap(TestKeys2, 'cfoo')
      vimp.xmap({
        'expr'
      }, TestKeys, function()
        return TestKeys2
      end)
      helpers.setLines({
        'qux bar'
      })
      helpers.input('0wviw')
      helpers.rinput(TestKeys)
      return assert.isEqual(helpers.getLine(), 'qux foo')
    end,
    testSmap = function(self)
      vimp.snoremap(TestKeys2, 'foo')
      vimp.smap({
        'expr'
      }, TestKeys, function()
        return TestKeys2
      end)
      helpers.input("istart mid end<esc>")
      assert.isEqual(helpers.getLine(), 'start mid end')
      helpers.input("Fmgh<right><right>")
      helpers.rinput(TestKeys)
      return assert.isEqual(helpers.getLine(), 'start foo end')
    end,
    testCmap = function(self)
      vimp.cnoremap(TestKeys2, 'foo')
      vimp.cmap({
        'expr'
      }, TestKeys, function()
        return TestKeys2
      end)
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='" .. tostring(TestKeys) .. "'<cr>")
      return assert.isEqual(vim.g.foo, 'foo')
    end,
    testOmap = function(self)
      vimp.onoremap(TestKeys2, 'iw')
      vimp.omap({
        'expr'
      }, TestKeys, function()
        return TestKeys2
      end)
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
