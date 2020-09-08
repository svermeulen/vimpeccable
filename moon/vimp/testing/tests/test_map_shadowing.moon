
require('vimp')

assert = require("vimp.util.assert")
log = require("vimp.util.log")
helpers = require("vimp.testing.helpers")

TestKeys1 = '<space>ab'
TestKeys2 = '<space>abc'

class Tester
  testDisallowsShadowing: =>
    -- helpers.unlet('foo')
    -- vimp.nnoremap TestKeys1, [[:let g:foo = 5<cr>]]
    -- assert.throws "blurg", ->
    --   vimp.nnoremap TestKeys2, [[:let g:foo = 2<cr>]]

