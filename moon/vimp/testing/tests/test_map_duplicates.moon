
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<f4>'

class Tester
  testDuplicatesAreNotAllowedByDefault: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys, [[:let g:foo = 5<cr>]]
    assert.throws 'duplicate mapping', ->
      vimp.nnoremap TestKeys, [[:let g:foo = 2<cr>]]

  testForceOption: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys, [[:let g:foo = 5<cr>]]
    vimp.nnoremap { 'force' }, TestKeys, [[:let g:foo = 2<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.isEqual(vim.g.foo, 2)

  testConflictWithVimMap1: =>
    helpers.unlet('foo')
    vim.cmd("nnoremap #{TestKeys} :<c-u>let g:foo = 2<cr>")
    assert.throws 'mapping already exists', ->
      vimp.nnoremap TestKeys, [[:let g:foo = 3<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.isEqual(vim.g.foo, 2)
    vim.cmd("nunmap <f4>")

  testConflictWithVimMap2: =>
    helpers.unlet('foo')
    vim.cmd("nnoremap #{TestKeys} :<c-u>let g:foo = 2<cr>")
    vimp.nnoremap { 'force' }, TestKeys, [[:let g:foo = 3<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.isEqual(vim.g.foo, 3)

