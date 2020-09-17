
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<f4>'

class Tester
  test_nnoremap: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys, [[:let g:foo = 5<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.is_equal(vim.g.foo, 5)

  test_inoremap: =>
    vimp.inoremap TestKeys, 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'foo')

  test_xnoremap: =>
    vimp.xnoremap TestKeys, 'cfoo'
    helpers.input("istart middle end<esc>")
    assert.is_equal(helpers.get_line!, 'start middle end')
    helpers.input("Fmviw")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'start foo end')

  test_snoremap: =>
    vimp.snoremap TestKeys, 'foo'
    helpers.input("istart mid end<esc>")
    assert.is_equal(helpers.get_line!, 'start mid end')
    helpers.input("Fmgh<right><right>")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'start foo end')

  test_cnoremap: =>
    vimp.cnoremap TestKeys, 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.is_equal(vim.g.foo, 'foo')

  test_onoremap: =>
    vimp.onoremap TestKeys, 'aw'
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'start end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- test_tnoremap: =>

  test_nmap: =>
    helpers.unlet('foo')
    vimp.nmap TestKeys, [[:let g:foo = 5<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.is_equal(vim.g.foo, 5)

  test_imap: =>
    vimp.imap TestKeys, 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'foo')

  test_xmap: =>
    vimp.xmap TestKeys, 'cfoo'
    helpers.input("istart middle end<esc>")
    assert.is_equal(helpers.get_line!, 'start middle end')
    helpers.input("Fmviw")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'start foo end')

  test_smap: =>
    vimp.smap TestKeys, 'foo'
    helpers.input("istart mid end<esc>")
    assert.is_equal(helpers.get_line!, 'start mid end')
    helpers.input("Fmgh<right><right>")
    helpers.rinput(TestKeys)
    assert.is_equal(helpers.get_line!, 'start foo end')

  test_cmap: =>
    vimp.cmap TestKeys, 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.is_equal(vim.g.foo, 'foo')

  test_omap: =>
    vimp.omap TestKeys, 'iw'
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'start  end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- test_tmap: =>
