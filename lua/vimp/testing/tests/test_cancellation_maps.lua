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
      helpers.set_lines({
        "abcdef"
      })
      assert.is_equal(vim.g.foo, nil)
      helpers.input("0fc")
      helpers.rinput('dlb')
      assert.is_equal(vim.g.foo, 5)
      assert.is_equal(helpers.get_line(), 'abcdef')
      helpers.rinput("dl<esc>")
      assert.is_equal(helpers.get_line(), 'abdef')
      helpers.set_lines({
        "abcdef"
      })
      helpers.input("0fc")
      vimp.add_chord_cancellations('n', 'd')
      helpers.rinput("dl<esc>")
      return assert.is_equal(helpers.get_line(), 'abcdef')
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
