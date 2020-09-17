
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<F4>'

class Tester
  _exec_in_temporary_buffer: (func) =>
    startBuffer = vim.api.nvim_get_current_buf()
    tempBuffer = vim.api.nvim_create_buf(true, false)
    vim.cmd("b #{tempBuffer}")
    func!
    vim.cmd("b #{startBuffer}")
    vim.cmd("bd! #{tempBuffer}")

  test_force_kill_buffer_before_unmap: =>
    @\_exec_in_temporary_buffer ->
      vimp.nnoremap { 'buffer' }, TestKeys, [[:let g:foo = 5<cr>]]
      assert.is_equal(vimp.total_num_maps, 1)
    assert.is_equal(vimp.total_num_maps, 0)

  test_nnoremap: =>
    helpers.unlet('foo')
    vimp.nnoremap { 'buffer' }, TestKeys, [[:let g:foo = 5<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.is_equal(vim.g.foo, 5)
    helpers.unlet('foo')
    @\_exec_in_temporary_buffer ->
      helpers.rinput(TestKeys)
      assert.is_equal(vim.g.foo, nil)

  test_inoremap: =>
    vimp.inoremap { 'buffer' }, TestKeys, 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'foo')
    @\_exec_in_temporary_buffer ->
      helpers.rinput(TestKeys)
      assert.is_equal(helpers.get_line!, '')

  test_xnoremap: =>
    vimp.xnoremap { 'buffer' }, TestKeys, 'cfoo'
    setupBuffer = ->
      helpers.input("istart middle end<esc>")
      assert.is_equal(helpers.get_line!, 'start middle end')
      helpers.input("Fmviw")
      helpers.rinput(TestKeys)
    setupBuffer!
    assert.is_equal(helpers.get_line!, 'start foo end')
    @\_exec_in_temporary_buffer ->
      setupBuffer!
      assert.is_equal(helpers.get_line!, 'start middle end')

  test_snoremap: =>
    vimp.snoremap { 'buffer' }, TestKeys, 'foo'
    setupBuffer = ->
      helpers.input("istart mid end<esc>")
      assert.is_equal(helpers.get_line!, 'start mid end')
      helpers.input("Fmgh<right><right>")
      helpers.rinput(TestKeys)
    setupBuffer!
    assert.is_equal(helpers.get_line!, 'start foo end')
    @\_exec_in_temporary_buffer ->
      setupBuffer!
      assert.is_equal(helpers.get_line!, 'start mid end')

  test_cnoremap: =>
    vimp.cnoremap { 'buffer' }, TestKeys, 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.is_equal(vim.g.foo, 'foo')
    @\_exec_in_temporary_buffer ->
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
      assert.is_equal(vim.g.foo, TestKeys)

  test_onoremap: =>
    vimp.onoremap { 'buffer' }, TestKeys, 'aw'
    setup = ->
      helpers.input("istart mid end<esc>Fm")
      helpers.rinput("d#{TestKeys}")
    setup!
    assert.is_equal(helpers.get_line!, 'start end')
    @\_exec_in_temporary_buffer ->
      setup!
      assert.is_equal(helpers.get_line!, 'start mid end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- test_tnoremap: =>

  test_nmap: =>
    helpers.unlet('foo')
    vimp.nmap { 'buffer' }, TestKeys, [[:let g:foo = 5<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.is_equal(vim.g.foo, 5)
    helpers.unlet('foo')
    @\_exec_in_temporary_buffer ->
      helpers.rinput(TestKeys)
      assert.is_equal(vim.g.foo, nil)

  test_imap: =>
    vimp.imap { 'buffer' }, TestKeys, 'foo'
    helpers.rinput("i#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'foo')
    @\_exec_in_temporary_buffer ->
      helpers.rinput("i#{TestKeys}<esc>")
      assert.is_equal(helpers.get_line!, TestKeys)

  test_xmap: =>
    vimp.xmap { 'buffer' }, TestKeys, 'cfoo'
    setup = ->
      helpers.input("istart middle end<esc>")
      assert.is_equal(helpers.get_line!, 'start middle end')
      helpers.input("Fmviw")
      helpers.rinput(TestKeys)
    setup!
    assert.is_equal(helpers.get_line!, 'start foo end')
    @\_exec_in_temporary_buffer ->
      setup!
      assert.is_equal(helpers.get_line!, "start middle end")

  test_smap: =>
    vimp.smap { 'buffer' }, TestKeys, 'foo'
    setup = ->
      helpers.input("istart mid end<esc>")
      assert.is_equal(helpers.get_line!, 'start mid end')
      helpers.input("Fmgh<right><right>")
      helpers.rinput(TestKeys)
    setup!
    assert.is_equal(helpers.get_line!, 'start foo end')
    @\_exec_in_temporary_buffer ->
      setup!
      assert.is_equal(helpers.get_line!, 'start mid end')

  test_cmap: =>
    vimp.cmap { 'buffer' }, TestKeys, 'foo'
    helpers.unlet('foo')
    helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
    assert.is_equal(vim.g.foo, 'foo')
    @\_exec_in_temporary_buffer ->
      helpers.unlet('foo')
      helpers.rinput(":let g:foo='#{TestKeys}'<cr>")
      assert.is_equal(vim.g.foo, TestKeys)

  test_omap: =>
    vimp.omap { 'buffer' }, TestKeys, 'iw'
    helpers.input("istart mid end<esc>Fm")
    helpers.rinput("d#{TestKeys}")
    assert.is_equal(helpers.get_line!, 'start  end')
    @\_exec_in_temporary_buffer ->
      helpers.input("istart mid end<esc>Fm")
      helpers.rinput("d#{TestKeys}")
      assert.is_equal(helpers.get_line!, 'start mid end')

  -- Skip this one because it's tricky to test
  -- Test it manually instead
  -- test_tmap: =>
