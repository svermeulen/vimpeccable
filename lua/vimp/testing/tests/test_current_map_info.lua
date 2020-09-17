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
    test_basic = function(self)
      local received = false
      vimp.nnoremap(TestKeys1, function()
        assert.is_equal(vimp.current_map_info.mode, 'n')
        assert.is_equal(vimp.current_map_info.lhs, TestKeys1)
        assert.is_equal(#vimp.maps_in_progress, 1)
        received = true
      end)
      assert.that(not received)
      helpers.rinput(TestKeys1)
      return assert.that(received)
    end,
    test_nested_maps = function(self)
      local received1 = false
      local received2 = false
      vimp.nnoremap(TestKeys1, function()
        assert.is_equal(vimp.current_map_info.mode, 'n')
        assert.is_equal(vimp.current_map_info.lhs, TestKeys1)
        assert.is_equal(#vimp.maps_in_progress, 2)
        received1 = true
      end)
      vimp.nnoremap(TestKeys2, function()
        assert.is_equal(vimp.current_map_info.mode, 'n')
        assert.is_equal(vimp.current_map_info.lhs, TestKeys2)
        assert.is_equal(#vimp.maps_in_progress, 1)
        helpers.rinput(TestKeys1)
        received2 = true
      end)
      assert.that(not received1)
      assert.that(not received2)
      helpers.rinput(TestKeys2)
      assert.that(received1)
      return assert.that(received2)
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
