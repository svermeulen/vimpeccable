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
    test_nnoremap = function(self)
      local received = false
      vimp.nnoremap(TestKeys, function()
        received = true
      end)
      assert.that(not received)
      helpers.rinput(TestKeys)
      return assert.that(received)
    end,
    test_inoremap = function(self)
      local received = false
      vimp.inoremap(TestKeys, function()
        received = true
      end)
      assert.that(not received)
      helpers.rinput("i" .. tostring(TestKeys) .. "foo")
      assert.is_equal(helpers.get_line(), 'foo')
      return assert.that(received)
    end,
    test_xnoremap = function(self)
      local received = false
      vimp.xnoremap(TestKeys, function()
        helpers.input("iw")
        received = true
      end)
      assert.that(not received)
      helpers.input("istart middle end<esc>Fmv")
      helpers.rinput(TestKeys)
      helpers.input("cfoo<esc>")
      assert.is_equal(helpers.get_line(), 'start foo end')
      return assert.that(received)
    end,
    test_snoremap = function(self)
      local received = false
      vimp.snoremap(TestKeys, function()
        received = true
      end)
      assert.that(not received)
      helpers.input("istart mid end<esc>Fm")
      helpers.input("gh<right><right>")
      helpers.rinput(TestKeys)
      helpers.input("foo")
      assert.is_equal(helpers.get_line(), 'start foo end')
      return assert.that(received)
    end,
    test_cnoremap = function(self)
      return assert.throws('not currently supported', function()
        local received = false
        return vimp.cnoremap(TestKeys, function()
          received = true
        end)
      end)
    end,
    test_onoremap = function(self)
      local received = false
      vimp.onoremap(TestKeys, function()
        helpers.input("viw")
        received = true
      end)
      assert.that(not received)
      helpers.input("istart middle end<esc>Fm")
      helpers.rinput("d" .. tostring(TestKeys))
      assert.is_equal(helpers.get_line(), 'start  end')
      return assert.that(received)
    end,
    test_tnoremap = function(self)
      return assert.throws('not currently supported', function()
        local received = false
        return vimp.tnoremap(TestKeys, function()
          received = true
        end)
      end)
    end,
    test_nmap = function(self)
      return assert.throws("Cannot use recursive", function()
        return vimp.nmap(TestKeys, function() end)
      end)
    end,
    test_imap = function(self)
      return assert.throws("Cannot use recursive", function()
        return vimp.imap(TestKeys, function() end)
      end)
    end,
    test_xmap = function(self)
      return assert.throws("Cannot use recursive", function()
        return vimp.xmap(TestKeys, function() end)
      end)
    end,
    test_smap = function(self)
      return assert.throws("Cannot use recursive", function()
        return vimp.smap(TestKeys, function() end)
      end)
    end,
    test_cmap = function(self)
      return assert.throws("not currently supported", function()
        return vimp.cmap(TestKeys, function() end)
      end)
    end,
    test_omap = function(self)
      return assert.throws("recursive mapping", function()
        return vimp.omap(TestKeys, function() end)
      end)
    end,
    test_tmap = function(self)
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
