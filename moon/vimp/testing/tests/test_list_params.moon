
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<F4>'
TestKeys2 = '<F5>'

class Tester
  test_multiple_lhs: =>
    helpers.unlet('foo')
    vimp.nnoremap { TestKeys1, TestKeys2 }, [[:let g:foo = 5<cr>]]
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys1)
    assert.is_equal(vim.g.foo, 5)
    helpers.unlet('foo')
    assert.is_equal(vim.g.foo, nil)
    helpers.rinput(TestKeys2)
    assert.is_equal(vim.g.foo, 5)

  test_multiple_modes: =>
    vimp.bind 'nx', { TestKeys1, TestKeys2 }, '<right>'
    helpers.set_lines({"abc def"})
    helpers.input('0')
    helpers.rinput(TestKeys1)
    assert.is_equal(helpers.get_cursor_character!, 'b')
    helpers.rinput(TestKeys2)
    assert.is_equal(helpers.get_cursor_character!, 'c')
    helpers.input("0v")
    helpers.rinput(TestKeys1)
    helpers.rinput(TestKeys2)
    helpers.input("d")
    assert.is_equal(helpers.get_line!, ' def')
