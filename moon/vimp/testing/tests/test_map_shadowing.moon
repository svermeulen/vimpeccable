
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<space>ab'
TestKeys2 = '<space>abc'

class Tester
  testDisallowsLongerMap: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys1, [[:let g:foo = 5<cr>]]
    assert.throws "Map conflict found", ->
      vimp.nnoremap TestKeys2, [[:let g:foo = 2<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.isEqual(vim.g.foo, 5)
    assert.isEqual(vimp.totalNumMaps, 1)

  testForceDoesNotWorkWithShadows: =>
    helpers.unlet('foo')
    vimp.nnoremap {'force'}, TestKeys1, [[:let g:foo = 5<cr>]]
    assert.throws "Map conflict found", ->
      vimp.nnoremap TestKeys2, [[:let g:foo = 2<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.isEqual(vim.g.foo, 5)
    assert.isEqual(vimp.totalNumMaps, 1)

  testDisallowsShorterMap: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys2, [[:let g:foo = 5<cr>]]
    assert.throws "Map conflict found", ->
      vimp.nnoremap TestKeys1, [[:let g:foo = 2<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    assert.isEqual(vim.g.foo, 5)
    assert.isEqual(vimp.totalNumMaps, 1)

