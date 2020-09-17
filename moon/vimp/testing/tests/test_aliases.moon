
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<F4>'
TestKeys2 = '<F5>'

class Tester
  test_simple_alias: =>
    helpers.unlet('foo')
    vimp.add_alias(TestKeys1, TestKeys2)
    vimp.nnoremap TestKeys1, [[:let g:foo = 5<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    assert.is_equal(vim.g.foo, 5)
    helpers.unlet('foo')
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.is_equal(vim.g.foo, nil)

  test_multiple_aliases: =>
    helpers.unlet('foo')
    vimp.add_alias('<d-g>', TestKeys1)
    vimp.add_alias('<d-e>', TestKeys2)
    vimp.nnoremap '<d-g><d-e>', [[:let g:foo = 5<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    helpers.input('<esc>')
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    helpers.input('<esc>')
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput("#{TestKeys1}#{TestKeys2}")
    assert.is_equal(vim.g.foo, 5)
