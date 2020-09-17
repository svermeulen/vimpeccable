
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys = '<f4>'

class Tester
  test_duplicates_are_not_allowed_by_default: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys, [[:let g:foo = 5<cr>]]
    assert.throws 'duplicate mapping', ->
      vimp.nnoremap TestKeys, [[:let g:foo = 2<cr>]]

  test_override_option: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys, [[:let g:foo = 5<cr>]]
    vimp.nnoremap { 'override' }, TestKeys, [[:let g:foo = 2<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.is_equal(vim.g.foo, 2)

  test_conflict_with_vim_map1: =>
    helpers.unlet('foo')
    vim.cmd("nnoremap #{TestKeys} :<c-u>let g:foo = 2<cr>")
    assert.throws 'mapping already exists', ->
      vimp.nnoremap TestKeys, [[:let g:foo = 3<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.is_equal(vim.g.foo, 2)
    vim.cmd("nunmap <f4>")

  test_conflict_with_vim_map2: =>
    helpers.unlet('foo')
    vim.cmd("nnoremap #{TestKeys} :<c-u>let g:foo = 2<cr>")
    vimp.nnoremap { 'override' }, TestKeys, [[:let g:foo = 3<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys)
    assert.is_equal(vim.g.foo, 3)

