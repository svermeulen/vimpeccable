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
      local received = false
      vimp.nnoremap(TestKeys, function()
        received = true
      end)
      assert.that(not received)
      helpers.rinput(TestKeys)
      return assert.that(received)
    end,
    testInoremap = function(self)
      local received = false
      vimp.inoremap(TestKeys, function()
        received = true
      end)
      assert.that(not received)
      helpers.rinput("i" .. tostring(TestKeys) .. "foo")
      assert.isEqual(helpers.getLine(), 'foo')
      return assert.that(received)
    end,
    testXnoremap = function(self)
      local received = false
      vimp.xnoremap(TestKeys, function()
        helpers.input("iw")
        received = true
      end)
      assert.that(not received)
      helpers.input("istart middle end<esc>Fmv")
      helpers.rinput(TestKeys)
      helpers.input("cfoo<esc>")
      assert.isEqual(helpers.getLine(), 'start foo end')
      return assert.that(received)
    end,
    testSnoremap = function(self)
      local received = false
      vimp.snoremap(TestKeys, function()
        received = true
      end)
      assert.that(not received)
      helpers.input("istart mid end<esc>Fm")
      helpers.input("gh<right><right>")
      helpers.rinput(TestKeys)
      helpers.input("foo")
      assert.isEqual(helpers.getLine(), 'start foo end')
      return assert.that(received)
    end,
    testCnoremap = function(self)
      return assert.throws('not currently supported', function()
        local received = false
        return vimp.cnoremap(TestKeys, function()
          received = true
        end)
      end)
    end,
    testOnoremap = function(self)
      local received = false
      vimp.onoremap(TestKeys, function()
        helpers.input("viw")
        received = true
      end)
      assert.that(not received)
      helpers.input("istart middle end<esc>Fm")
      helpers.rinput("d" .. tostring(TestKeys))
      assert.isEqual(helpers.getLine(), 'start  end')
      return assert.that(received)
    end,
    testTnoremap = function(self)
      return assert.throws('not currently supported', function()
        local received = false
        return vimp.tnoremap(TestKeys, function()
          received = true
        end)
      end)
    end,
    testNmap = function(self)
      return assert.throws("Cannot use recursive", function()
        return vimp.nmap(TestKeys, function() end)
      end)
    end,
    testImap = function(self)
      return assert.throws("Cannot use recursive", function()
        return vimp.imap(TestKeys, function() end)
      end)
    end,
    testXmap = function(self)
      return assert.throws("Cannot use recursive", function()
        return vimp.xmap(TestKeys, function() end)
      end)
    end,
    testSmap = function(self)
      return assert.throws("Cannot use recursive", function()
        return vimp.smap(TestKeys, function() end)
      end)
    end,
    testCmap = function(self)
      return assert.throws("not currently supported", function()
        return vimp.cmap(TestKeys, function() end)
      end)
    end,
    testOmap = function(self)
      return assert.throws("recursive mapping", function()
        return vimp.omap(TestKeys, function() end)
      end)
    end,
    testTmap = function(self)
      return assert.throws("not currently supported", function()
        return vimp.tmap(TestKeys, function() end)
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
