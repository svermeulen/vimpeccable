
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<F4>'
TestKeys2 = '<F5>'

class Tester
  test_nnoremap: =>
    received = false
    vimp.nnoremap TestKeys, ->
      received = true
    assert.that(not received)
    helpers.rinput(TestKeys)
    assert.that(received)

  test_inoremap: =>
    received = false
    vimp.inoremap TestKeys, ->
      received = true
    assert.that(not received)
    helpers.rinput("i#{TestKeys}foo")
    assert.is_equal(helpers.get_line!, 'foo')
    assert.that(received)

  test_xnoremap: =>
    received = false
    vimp.xnoremap TestKeys, ->
      helpers.input("iw")
      received = true
    assert.that(not received)
    helpers.input("istart middle end<esc>Fmv")
    helpers.rinput(TestKeys)
    helpers.input("cfoo<esc>")
    assert.is_equal(helpers.get_line!, 'start foo end')
    assert.that(received)

  test_snoremap: =>
    received = false
    vimp.snoremap TestKeys, ->
      received = true
    assert.that(not received)

    helpers.input("istart mid end<esc>Fm")
    helpers.input("gh<right><right>")
    helpers.rinput(TestKeys)
    helpers.input("foo")
    assert.is_equal(helpers.get_line!, 'start foo end')
    assert.that(received)

  test_cnoremap: =>
    -- Not supported
    assert.throws 'not currently supported', ->
      received = false
      vimp.cnoremap TestKeys, ->
        received = true

  test_onoremap: =>
    received = false
    vimp.onoremap TestKeys, ->
      helpers.input("viw")
      received = true
    assert.that(not received)
    helpers.input("istart middle end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'start  end')
    assert.that(received)

  test_tnoremap: =>
    -- Not supported
    assert.throws 'not currently supported', ->
      received = false
      vimp.tnoremap TestKeys, ->
        received = true

  test_nmap: =>
    assert.throws "Cannot use recursive", ->
      vimp.nmap TestKeys, ->
        -- do nothing

  test_imap: =>
    assert.throws "Cannot use recursive", ->
      vimp.imap TestKeys, ->
        -- do nothing

  test_xmap: =>
    assert.throws "Cannot use recursive", ->
      vimp.xmap TestKeys, ->
        -- do nothing

  test_smap: =>
    assert.throws "Cannot use recursive", ->
      vimp.smap TestKeys, ->
        -- do nothing

  test_cmap: =>
    assert.throws "not currently supported", ->
      vimp.cmap TestKeys, ->
        -- do nothing

  test_omap: =>
    assert.throws "recursive mapping", ->
      vimp.omap TestKeys, ->
        -- do nothing

  test_tmap: =>
    assert.throws "not currently supported", ->
      vimp.tmap TestKeys, ->
        -- do nothing

