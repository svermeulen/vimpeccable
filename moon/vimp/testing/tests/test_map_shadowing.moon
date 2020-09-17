
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<space>ab'
TestKeys2 = '<space>abc'

class Tester
  test_disallows_longer_map: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys1, [[:let g:foo = 5<cr>]]
    assert.throws "Map conflict found", ->
      vimp.nnoremap TestKeys2, [[:let g:foo = 2<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.is_equal(vim.g.foo, 5)
    assert.is_equal(vimp.total_num_maps, 1)

  test_override_does_not_work_with_shadows: =>
    helpers.unlet('foo')
    vimp.nnoremap {'override'}, TestKeys1, [[:let g:foo = 5<cr>]]
    assert.throws "Map conflict found", ->
      vimp.nnoremap TestKeys2, [[:let g:foo = 2<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.is_equal(vim.g.foo, 5)
    assert.is_equal(vimp.total_num_maps, 1)

  test_disallows_shorter_map: =>
    helpers.unlet('foo')
    vimp.nnoremap TestKeys2, [[:let g:foo = 5<cr>]]
    assert.throws "Map conflict found", ->
      vimp.nnoremap TestKeys1, [[:let g:foo = 2<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    assert.is_equal(vim.g.foo, 5)
    assert.is_equal(vimp.total_num_maps, 1)

