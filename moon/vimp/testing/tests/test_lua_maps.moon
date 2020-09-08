
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<F4>'
TestKeys2 = '<F5>'

class Tester
  testNnoremap: =>
    received = false
    vimp.nnoremap TestKeys, ->
      received = true
    assert.that(not received)
    helpers.rinput(TestKeys)
    assert.that(received)

  testInoremap: =>
    received = false
    vimp.inoremap TestKeys, ->
      received = true
    assert.that(not received)
    helpers.rinput("i#{TestKeys}foo")
    assert.isEqual(helpers.getLine!, 'foo')
    assert.that(received)

  testXnoremap: =>
    received = false
    vimp.xnoremap TestKeys, ->
      helpers.input("iw")
      received = true
    assert.that(not received)
    helpers.input("istart middle end<esc>Fmv")
    helpers.rinput(TestKeys)
    helpers.input("cfoo<esc>")
    assert.isEqual(helpers.getLine!, 'start foo end')
    assert.that(received)

  testSnoremap: =>
    received = false
    vimp.snoremap TestKeys, ->
      received = true
    assert.that(not received)

    helpers.input("istart mid end<esc>Fm")
    helpers.input("gh<right><right>")
    helpers.rinput(TestKeys)
    helpers.input("foo")
    assert.isEqual(helpers.getLine!, 'start foo end')
    assert.that(received)

  testCnoremap: =>
    -- Not supported
    assert.throws 'not currently supported', ->
      received = false
      vimp.cnoremap TestKeys, ->
        received = true

  testOnoremap: =>
    received = false
    vimp.onoremap TestKeys, ->
      helpers.input("viw")
      received = true
    assert.that(not received)
    helpers.input("istart middle end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'start  end')
    assert.that(received)

  testTnoremap: =>
    -- Not supported
    assert.throws 'not currently supported', ->
      received = false
      vimp.tnoremap TestKeys, ->
        received = true

  testNmap: =>
    assert.throws "Cannot use recursive", ->
      vimp.nmap TestKeys, ->
        -- do nothing

  testImap: =>
    assert.throws "Cannot use recursive", ->
      vimp.imap TestKeys, ->
        -- do nothing

  testXmap: =>
    assert.throws "Cannot use recursive", ->
      vimp.xmap TestKeys, ->
        -- do nothing

  testSmap: =>
    assert.throws "Cannot use recursive", ->
      vimp.smap TestKeys, ->
        -- do nothing

  testCmap: =>
    assert.throws "not currently supported", ->
      vimp.cmap TestKeys, ->
        -- do nothing

  testOmap: =>
    assert.throws "recursive mapping", ->
      vimp.omap TestKeys, ->
        -- do nothing

  testTmap: =>
    assert.throws "not currently supported", ->
      vimp.tmap TestKeys, ->
        -- do nothing

