
assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")
UniqueTrie = require("vimp.unique_trie")

class Tester
  test1: =>
    helpers.unlet('foo')
    vimp.nnoremap 'dlb', [[:let g:foo = 5<cr>]]
    helpers.setLines({"abcdef"})
    assert.isEqual(vim.g.foo, nil)
    helpers.input("0fc")
    helpers.rinput('dlb')
    assert.isEqual(vim.g.foo, 5)
    assert.isEqual(helpers.getLine!, 'abcdef')
    helpers.rinput("dl<esc>")
    assert.isEqual(helpers.getLine!, 'abdef')
    helpers.setLines({"abcdef"})
    helpers.input("0fc")
    vimp.addChordCancellations('n', 'd')
    helpers.rinput("dl<esc>")
    assert.isEqual(helpers.getLine!, 'abcdef')
