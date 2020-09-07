
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<f4>'

class Tester
  testNnoremap: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys, [[:let g:foo = 5<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.isEqual(vim.g.foo, 5)

  testInoremap: =>
    vimp.inoremap TestKeys, 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'foo')

  testXnoremap: =>
    vimp.xnoremap TestKeys, 'cfoo'
    helpers.input("istart middle end<esc>")
    assert.isEqual(helpers.getLine!, 'start middle end')
    helpers.input("Fmviw")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'start foo end')

  testSnoremap: =>
    vimp.snoremap TestKeys, 'foo'
    helpers.input("istart mid end<esc>")
    assert.isEqual(helpers.getLine!, 'start mid end')
    helpers.input("Fmgh<right><right>")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'start foo end')

  testCnoremap: =>
    vimp.cnoremap TestKeys, 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.isEqual(vim.g.foo, 'foo')

  testOnoremap: =>
    vimp.onoremap TestKeys, 'aw'
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'start end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- testTnoremap: =>

  testNmap: =>
    helpers.unlet('foo')
    vimp.nmap TestKeys, [[:let g:foo = 5<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.isEqual(vim.g.foo, 5)

  testImap: =>
    vimp.imap TestKeys, 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'foo')

  testXmap: =>
    vimp.xmap TestKeys, 'cfoo'
    helpers.input("istart middle end<esc>")
    assert.isEqual(helpers.getLine!, 'start middle end')
    helpers.input("Fmviw")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'start foo end')

  testSmap: =>
    vimp.smap TestKeys, 'foo'
    helpers.input("istart mid end<esc>")
    assert.isEqual(helpers.getLine!, 'start mid end')
    helpers.input("Fmgh<right><right>")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'start foo end')

  testCmap: =>
    vimp.cmap TestKeys, 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.isEqual(vim.g.foo, 'foo')

  testOmap: =>
    vimp.omap TestKeys, 'iw'
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'start  end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- testTmap: =>
