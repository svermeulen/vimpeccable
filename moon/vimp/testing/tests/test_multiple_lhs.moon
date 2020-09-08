
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<F4>'
TestKeys2 = '<F5>'

class Tester
  testNnoremap: =>
    helpers.unlet('foo')
    vimp.nnoremap { TestKeys1, TestKeys2 }, [[:let g:foo = 5<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.isEqual(vim.g.foo, 5)
    helpers.unlet('foo')
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    assert.isEqual(vim.g.foo, 5)

