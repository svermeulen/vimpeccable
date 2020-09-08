
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<F4>'
TestKeys2 = '<F5>'

class Tester
  testBufferBlock: =>
    helpers.unlet('foo')
    startBuffer = vim.api.nvim_get_current_buf()
    tempBuffer = vim.api.nvim_create_buf(true, false)
    assert.isEqual(startBuffer, vim.api.nvim_get_current_buf())
    vimp.addBufferMaps tempBuffer, ->
      vimp.nnoremap TestKeys1, [[:let g:foo = 5<cr>]]
      vimp.nnoremap TestKeys2, [[:let g:foo = 7<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    assert.isEqual(vim.g.foo, nil)
    vim.cmd("b #{tempBuffer}")
    helpers.rinput(TestKeys1)
    assert.isEqual(vim.g.foo, 5)
    helpers.rinput(TestKeys2)
    assert.isEqual(vim.g.foo, 7)

  testBufferBlockOnlyOneAtATime: =>
    startBuffer = vim.api.nvim_get_current_buf()
    tempBuffer = vim.api.nvim_create_buf(true, false)
    assert.isEqual(startBuffer, vim.api.nvim_get_current_buf())
    assert.throws "Already in a call to vimp.addBufferMaps", ->
      vimp.addBufferMaps tempBuffer, ->
        vimp.nnoremap TestKeys1, [[:let g:foo = 5<cr>]]
        vimp.addBufferMaps startBuffer, ->
          vimp.nnoremap TestKeys2, [[:let g:foo = 7<cr>]]
