
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<F4>'
TestKeys2 = '<F5>'

class Tester
  testNnoremap: =>
    helpers.unlet('foo')
    vimp.nnoremap { 'expr' }, TestKeys, -> [[:let g:foo = 5<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.isEqual(vim.g.foo, 5)

  testInoremap: =>
    vimp.inoremap { 'expr' }, TestKeys, -> 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'foo')

  testXnoremap: =>
    vimp.xnoremap { 'expr' }, TestKeys, -> 'cfoo'
    helpers.input("istart middle end<esc>")
    assert.isEqual(helpers.getLine!, 'start middle end')
    helpers.input("Fmviw")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'start foo end')

  testSnoremap: =>
    vimp.snoremap { 'expr' }, TestKeys, -> 'foo'
    helpers.input("istart mid end<esc>")
    assert.isEqual(helpers.getLine!, 'start mid end')
    helpers.input("Fmgh<right><right>")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'start foo end')

  testCnoremap: =>
    vimp.cnoremap { 'expr' }, TestKeys, -> 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.isEqual(vim.g.foo, 'foo')

  testOnoremap: =>
    vimp.onoremap { 'expr' }, TestKeys, -> 'aw'
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'start end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- testTnoremap: =>

  testNmap: =>
    vimp.nnoremap TestKeys2, 'diw'
    vimp.nmap {'expr'}, TestKeys, -> TestKeys2
    helpers.setLines({'foo bar qux'})
    helpers.input("0w")
    helpers.rinput("#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'foo  qux')

  testImap: =>
    vimp.inoremap TestKeys2, 'qux'
    vimp.imap {'expr'}, TestKeys, -> TestKeys2
    helpers.setLines({'foo bar'})
    helpers.input("0w")
    helpers.rinput("i#{TestKeys}<esc>")
    assert.isEqual(helpers.getLine!, 'foo quxbar')

  testXmap: =>
    vimp.xnoremap TestKeys2, 'cfoo'
    vimp.xmap {'expr'}, TestKeys, -> TestKeys2
    helpers.setLines({'qux bar'})
    helpers.input('0wviw')
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'qux foo')

  testSmap: =>
    vimp.snoremap TestKeys2, 'foo'
    vimp.smap {'expr'}, TestKeys, -> TestKeys2
    helpers.input("istart mid end<esc>")
    assert.isEqual(helpers.getLine!, 'start mid end')
    helpers.input("Fmgh<right><right>")
    helpers.rinput(TestKeys)
    assert.isEqual(helpers.getLine!, 'start foo end')

  testCmap: =>
    vimp.cnoremap TestKeys2, 'foo'
    vimp.cmap {'expr'}, TestKeys, -> TestKeys2
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.isEqual(vim.g.foo, 'foo')

  testOmap: =>
    vimp.onoremap TestKeys2, 'iw'
    vimp.omap {'expr'}, TestKeys, -> TestKeys2
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'start  end')
