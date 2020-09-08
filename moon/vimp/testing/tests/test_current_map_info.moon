
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<F4>'
TestKeys2 = '<F5>'

class Tester
  testBasic: =>
    received = false
    vimp.nnoremap TestKeys1, ->
      assert.isEqual(vimp.currentMapInfo.mode, 'n')
      assert.isEqual(vimp.currentMapInfo.lhs, TestKeys1)
      assert.isEqual(#vimp.mapsInProgress, 1)
      received = true
    assert.that(not received)
    helpers.rinput(TestKeys1)
    assert.that(received)

  testNestedMaps: =>
    received1 = false
    received2 = false

    vimp.nnoremap TestKeys1, ->
      assert.isEqual(vimp.currentMapInfo.mode, 'n')
      assert.isEqual(vimp.currentMapInfo.lhs, TestKeys1)
      assert.isEqual(#vimp.mapsInProgress, 2)
      received1 = true

    vimp.nnoremap TestKeys2, ->
      assert.isEqual(vimp.currentMapInfo.mode, 'n')
      assert.isEqual(vimp.currentMapInfo.lhs, TestKeys2)
      assert.isEqual(#vimp.mapsInProgress, 1)
      helpers.rinput(TestKeys1)
      received2 = true

    assert.that(not received1)
    assert.that(not received2)
    helpers.rinput(TestKeys2)
    assert.that(received1)
    assert.that(received2)
