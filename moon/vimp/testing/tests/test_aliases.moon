
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<F4>'
TestKeys2 = '<F5>'

class Tester
  testSimpleAlias: =>
    helpers.unlet('foo')
    vimp.addAlias(TestKeys1, TestKeys2)
    vimp.nnoremap TestKeys1, [[:let g:foo = 5<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    assert.isEqual(vim.g.foo, 5)
    helpers.unlet('foo')
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.isEqual(vim.g.foo, nil)

  testMultipleAliases: =>
    helpers.unlet('foo')
    vimp.addAlias('<d-g>', TestKeys1)
    vimp.addAlias('<d-e>', TestKeys2)
    vimp.nnoremap '<d-g><d-e>', [[:let g:foo = 5<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    helpers.input('<esc>')
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    helpers.input('<esc>')
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput("#{TestKeys1}#{TestKeys2}")
    assert.isEqual(vim.g.foo, 5)
