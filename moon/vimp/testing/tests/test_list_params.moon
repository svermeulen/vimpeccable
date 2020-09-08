
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<F4>'
TestKeys2 = '<F5>'

class Tester
  testMultipleLhs: =>
    helpers.unlet('foo')
    vimp.nnoremap { TestKeys1, TestKeys2 }, [[:let g:foo = 5<cr>]]
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.isEqual(vim.g.foo, 5)
    helpers.unlet('foo')
    assert.isEqual(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    assert.isEqual(vim.g.foo, 5)

  testMultipleModes: =>
    vimp.bind 'nx', { TestKeys1, TestKeys2 }, '<right>'
    helpers.setLines({"abc def"})
    helpers.input('0')
    helpers.rinput(TestKeys1)
    assert.isEqual(helpers.getCursorCharacter!, 'b')
    helpers.rinput(TestKeys2)
    assert.isEqual(helpers.getCursorCharacter!, 'c')
    helpers.input("0v")
    helpers.rinput(TestKeys1)
    helpers.rinput(TestKeys2)
    helpers.input("d")
    assert.isEqual(helpers.getLine!, ' def')
