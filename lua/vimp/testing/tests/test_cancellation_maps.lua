local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local UniqueTrie = require("vimp.unique_trie")
local Tester
do
  local _class_0
  local _base_0 = {
    test1 = function(self)
      helpers.unlet('foo')
      vimp.nnoremap('dlb', [[:let g:foo = 5<cr>]])
      helpers.setLines({
        "abcdef"
      })
      assert.isEqual(vim.g.foo, nil)
      helpers.input("0fc")
      helpers.rinput('dlb')
      assert.isEqual(vim.g.foo, 5)
      assert.isEqual(helpers.getLine(), 'abcdef')
      helpers.rinput("dl<esc>")
      assert.isEqual(helpers.getLine(), 'abdef')
      helpers.setLines({
        "abcdef"
      })
      helpers.input("0fc")
      vimp.addChordCancellations('n', 'd')
      helpers.rinput("dl<esc>")
      return assert.isEqual(helpers.getLine(), 'abcdef')
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Tester"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Tester = _class_0
  return _class_0
end
