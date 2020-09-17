
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<F4>'
TestKeys2 = '<F5>'

class Tester
  test_nnoremap: =>
    helpers.unlet('foo')
    vimp.nnoremap { 'expr' }, TestKeys, -> [[:let g:foo = 5<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.is_equal(vim.g.foo, 5)

  test_inoremap: =>
    vimp.inoremap { 'expr' }, TestKeys, -> 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'foo')

  test_xnoremap: =>
    vimp.xnoremap { 'expr' }, TestKeys, -> 'cfoo'
    helpers.input("istart middle end<esc>")
    assert.is_equal(helpers.get_line!, 'start middle end')
    helpers.input("Fmviw")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'start foo end')

  test_snoremap: =>
    vimp.snoremap { 'expr' }, TestKeys, -> 'foo'
    helpers.input("istart mid end<esc>")
    assert.is_equal(helpers.get_line!, 'start mid end')
    helpers.input("Fmgh<right><right>")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'start foo end')

  test_cnoremap: =>
    vimp.cnoremap { 'expr' }, TestKeys, -> 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.is_equal(vim.g.foo, 'foo')

  test_onoremap: =>
    vimp.onoremap { 'expr' }, TestKeys, -> 'aw'
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'start end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- test_tnoremap: =>

  test_nmap: =>
    vimp.nnoremap TestKeys2, 'diw'
    vimp.nmap {'expr'}, TestKeys, -> TestKeys2
    helpers.set_lines({'foo bar qux'})
    helpers.input("0w")
    helpers.rinput("#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'foo  qux')

  test_imap: =>
    vimp.inoremap TestKeys2, 'qux'
    vimp.imap {'expr'}, TestKeys, -> TestKeys2
    helpers.set_lines({'foo bar'})
    helpers.input("0w")
    helpers.rinput("i#{TestKeys}<esc>")
    assert.is_equal(helpers.get_line!, 'foo quxbar')

  test_xmap: =>
    vimp.xnoremap TestKeys2, 'cfoo'
    vimp.xmap {'expr'}, TestKeys, -> TestKeys2
    helpers.set_lines({'qux bar'})
    helpers.input('0wviw')
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'qux foo')

  test_smap: =>
    vimp.snoremap TestKeys2, 'foo'
    vimp.smap {'expr'}, TestKeys, -> TestKeys2
    helpers.input("istart mid end<esc>")
    assert.is_equal(helpers.get_line!, 'start mid end')
    helpers.input("Fmgh<right><right>")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'start foo end')

  test_cmap: =>
    vimp.cnoremap TestKeys2, 'foo'
    vimp.cmap {'expr'}, TestKeys, -> TestKeys2
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.is_equal(vim.g.foo, 'foo')

  test_omap: =>
    vimp.onoremap TestKeys2, 'iw'
    vimp.omap {'expr'}, TestKeys, -> TestKeys2
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'start  end')
