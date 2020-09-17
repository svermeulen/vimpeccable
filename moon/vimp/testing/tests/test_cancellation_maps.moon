
assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")
UniqueTrie = require("vimp.unique_trie")

class Tester
  test1: =>
    helpers.unlet('foo')
    vimp.nnoremap 'dlb', [[:let g:foo = 5<cr>]]
    helpers.set_lines({"abcdef"})
    assert.is_equal(vim.g.foo, nil)
    helpers.input("0fc")
    helpers.rinput('dlb')
    assert.is_equal(vim.g.foo, 5)
    assert.is_equal(helpers.get_line!, 'abcdef')
    helpers.rinput("dl<esc>")
    assert.is_equal(helpers.get_line!, 'abdef')
    helpers.set_lines({"abcdef"})
    helpers.input("0fc")
    vimp.add_chord_cancellations('n', 'd')
    helpers.rinput("dl<esc>")
    assert.is_equal(helpers.get_line!, 'abcdef')
