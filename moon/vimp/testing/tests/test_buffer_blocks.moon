
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<F4>'
TestKeys2 = '<F5>'

class Tester
  test_buffer_block: =>
    helpers.unlet('foo')
    startBuffer = vim.api.nvim_get_current_buf()
    tempBuffer = vim.api.nvim_create_buf(true, false)
    assert.is_equal(startBuffer, vim.api.nvim_get_current_buf())
    vimp.add_buffer_maps tempBuffer, ->
      vimp.nnoremap TestKeys1, [[:let g:foo = 5<cr>]]
      vimp.nnoremap TestKeys2, [[:let g:foo = 7<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    assert.is_equal(vim.g.foo, nil)
    vim.cmd("b #{tempBuffer}")
    helpers.rinput(TestKeys1)
    assert.is_equal(vim.g.foo, 5)
    helpers.rinput(TestKeys2)
    assert.is_equal(vim.g.foo, 7)

  test_buffer_block_only_one_at_a_time: =>
    startBuffer = vim.api.nvim_get_current_buf()
    tempBuffer = vim.api.nvim_create_buf(true, false)
    assert.is_equal(startBuffer, vim.api.nvim_get_current_buf())
    assert.throws "Already in a call to vimp.add_buffer_maps", ->
      vimp.add_buffer_maps tempBuffer, ->
        vimp.nnoremap TestKeys1, [[:let g:foo = 5<cr>]]
        vimp.add_buffer_maps startBuffer, ->
          vimp.nnoremap TestKeys2, [[:let g:foo = 7<cr>]]
