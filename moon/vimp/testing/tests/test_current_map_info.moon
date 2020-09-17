
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<F4>'
TestKeys2 = '<F5>'

class Tester
  test_basic: =>
    received = false
    vimp.nnoremap TestKeys1, ->
      assert.is_equal(vimp.current_map_info.mode, 'n')
      assert.is_equal(vimp.current_map_info.lhs, TestKeys1)
      assert.is_equal(#vimp.maps_in_progress, 1)
      received = true
    assert.that(not received)
    helpers.rinput(TestKeys1)
    assert.that(received)

  test_nested_maps: =>
    received1 = false
    received2 = false

    vimp.nnoremap TestKeys1, ->
      assert.is_equal(vimp.current_map_info.mode, 'n')
      assert.is_equal(vimp.current_map_info.lhs, TestKeys1)
      assert.is_equal(#vimp.maps_in_progress, 2)
      received1 = true

    vimp.nnoremap TestKeys2, ->
      assert.is_equal(vimp.current_map_info.mode, 'n')
      assert.is_equal(vimp.current_map_info.lhs, TestKeys2)
      assert.is_equal(#vimp.maps_in_progress, 1)
      helpers.rinput(TestKeys1)
      received2 = true

    assert.that(not received1)
    assert.that(not received2)
    helpers.rinput(TestKeys2)
    assert.that(received1)
    assert.that(received2)
