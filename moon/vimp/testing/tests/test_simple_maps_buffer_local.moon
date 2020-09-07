
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<F4>'

class Tester
  _execInTemporaryBuffer: (func) =>
    startBuffer = vim.api.nvim_get_current_buf()
    tempBuffer = vim.api.nvim_create_buf(true, false)
    vim.cmd("b #{tempBuffer}")
    func!
    vim.cmd("b #{startBuffer}")
    vim.cmd("bd! #{tempBuffer}")

  testForceKillBufferBeforeUnmap: =>
    @\_execInTemporaryBuffer ->
      vimp.nnoremap { 'buffer' }, TestKeys, [[:let g:foo = 5<cr>]]
      assert.isEqual(vimp.totalNumMaps, 1)
    assert.isEqual(vimp.totalNumMaps, 0)

  testNnoremap: =>
    helpers.unlet('foo')
    vimp.nnoremap { 'buffer' }, TestKeys, [[:let g:foo = 5<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.isEqual(vim.g.foo, 5)
    helpers.unlet('foo')
    @\_execInTemporaryBuffer ->
      helpers.rinput(TestKeys)
      assert.isEqual(vim.g.foo, nil)

  testInoremap: =>
    vimp.inoremap { 'buffer' }, TestKeys, 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'foo')
    @\_execInTemporaryBuffer ->
      helpers.rinput(TestKeys)
      assert.isEqual(helpers.getLine!, '')

  testXnoremap: =>
    vimp.xnoremap { 'buffer' }, TestKeys, 'cfoo'
    setupBuffer = ->
      helpers.input("istart middle end<esc>")
      assert.isEqual(helpers.getLine!, 'start middle end')
      helpers.input("Fmviw")
      helpers.rinput(TestKeys)
    setupBuffer!
    assert.isEqual(helpers.getLine!, 'start foo end')
    @\_execInTemporaryBuffer ->
      setupBuffer!
      assert.isEqual(helpers.getLine!, 'start middle end')

  testSnoremap: =>
    vimp.snoremap { 'buffer' }, TestKeys, 'foo'
    setupBuffer = ->
      helpers.input("istart mid end<esc>")
      assert.isEqual(helpers.getLine!, 'start mid end')
      helpers.input("Fmgh<right><right>")
      helpers.rinput(TestKeys)
    setupBuffer!
    assert.isEqual(helpers.getLine!, 'start foo end')
    @\_execInTemporaryBuffer ->
      setupBuffer!
      assert.isEqual(helpers.getLine!, 'start mid end')

  testCnoremap: =>
    vimp.cnoremap { 'buffer' }, TestKeys, 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.isEqual(vim.g.foo, 'foo')
    @\_execInTemporaryBuffer ->
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
      assert.isEqual(vim.g.foo, TestKeys)

  testOnoremap: =>
    vimp.onoremap { 'buffer' }, TestKeys, 'aw'
    setup = ->
      helpers.input("istart mid end<esc>Fm")
      helpers.rinput("d#{TestKeys}")
    setup!
    assert.isEqual(helpers.getLine!, 'start end')
    @\_execInTemporaryBuffer ->
      setup!
      assert.isEqual(helpers.getLine!, 'start mid end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- testTnoremap: =>

  testNmap: =>
    helpers.unlet('foo')
    vimp.nmap { 'buffer' }, TestKeys, [[:let g:foo = 5<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.isEqual(vim.g.foo, 5)
    helpers.unlet('foo')
    @\_execInTemporaryBuffer ->
      helpers.rinput(TestKeys)
      assert.isEqual(vim.g.foo, nil)

  testImap: =>
    vimp.imap { 'buffer' }, TestKeys, 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'foo')
    @\_execInTemporaryBuffer ->
      helpers.rinput("i#{TestKeys}<esc>")
      assert.isEqual(helpers.getLine!, TestKeys)

  testXmap: =>
    vimp.xmap { 'buffer' }, TestKeys, 'cfoo'
    setup = ->
      helpers.input("istart middle end<esc>")
      assert.isEqual(helpers.getLine!, 'start middle end')
      helpers.input("Fmviw")
      helpers.rinput(TestKeys)
    setup!
    assert.isEqual(helpers.getLine!, 'start foo end')
    @\_execInTemporaryBuffer ->
      setup!
      assert.isEqual(helpers.getLine!, "start middle end")

  testSmap: =>
    vimp.smap { 'buffer' }, TestKeys, 'foo'
    setup = ->
      helpers.input("istart mid end<esc>")
      assert.isEqual(helpers.getLine!, 'start mid end')
      helpers.input("Fmgh<right><right>")
      helpers.rinput(TestKeys)
    setup!
    assert.isEqual(helpers.getLine!, 'start foo end')
    @\_execInTemporaryBuffer ->
      setup!
      assert.isEqual(helpers.getLine!, 'start mid end')

  testCmap: =>
    vimp.cmap { 'buffer' }, TestKeys, 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.isEqual(vim.g.foo, 'foo')
    @\_execInTemporaryBuffer ->
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
      assert.isEqual(vim.g.foo, TestKeys)

  testOmap: =>
    vimp.omap { 'buffer' }, TestKeys, 'iw'
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.isEqual(helpers.getLine!, 'start  end')
    @\_execInTemporaryBuffer ->
      helpers.input("istart mid end<esc>Fm")
      helpers.rinput("d#{TestKeys}")
      assert.isEqual(helpers.getLine!, 'start mid end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- testTmap: =>
