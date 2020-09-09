local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local UniqueTrie = require("vimp.unique_trie")
local Tester
do
  local _class_0
  local _base_0 = {
    testAdds = function(self)
      local trie = UniqueTrie()
      local succeeded, existingPrefix, exactMatch = trie:tryAdd('abc')
      assert.that(succeeded)
      assert.that(existingPrefix == nil)
      assert.that(not exactMatch)
      succeeded, existingPrefix, exactMatch = trie:tryAdd('abc')
      assert.that(not succeeded)
      assert.that(existingPrefix == 'abc')
      assert.that(exactMatch)
      succeeded, existingPrefix, exactMatch = trie:tryAdd('abcd')
      assert.that(not succeeded)
      assert.that(existingPrefix == 'abc')
      assert.that(not exactMatch)
      succeeded, existingPrefix, exactMatch = trie:tryAdd('abxyz')
      assert.that(succeeded)
      assert.that(existingPrefix == nil)
      assert.that(not exactMatch)
      succeeded, existingPrefix, exactMatch = trie:tryAdd('a')
      assert.that(not succeeded)
      assert.that(existingPrefix == 'a')
      assert.that(not exactMatch)
      helpers.assertSameContents(trie:getAllEntries(), {
        'abc',
        'abxyz'
      })
      helpers.assertSameContents(trie:getAllSuffixes(''), {
        'abc',
        'abxyz'
      })
      helpers.assertSameContents(trie:getAllSuffixes('a'), {
        'bc',
        'bxyz'
      })
      helpers.assertSameContents(trie:getAllSuffixes('ab'), {
        'c',
        'xyz'
      })
      return helpers.assertSameContents(trie:getAllSuffixes('abc'), { })
    end,
    testRemove = function(self)
      local trie = UniqueTrie()
      local succeeded, existingPrefix, exactMatch = trie:tryAdd('ab')
      assert.that(succeeded)
      helpers.assertSameContents(trie:getAllEntries(), {
        'ab'
      })
      assert.that(not trie:tryRemove('a'))
      assert.that(trie:tryRemove('ab'))
      helpers.assertSameContents(trie:getAllEntries(), { })
      succeeded, existingPrefix, exactMatch = trie:tryAdd('ab')
      assert.that(succeeded)
      succeeded, existingPrefix, exactMatch = trie:tryAdd('acdef')
      assert.that(succeeded)
      succeeded, existingPrefix, exactMatch = trie:tryAdd('acdz')
      assert.that(succeeded)
      assert.that(not trie:tryRemove('a'))
      assert.that(not trie:tryRemove('ac'))
      assert.that(not trie:tryRemove('acd'))
      helpers.assertSameContents(trie:getAllEntries(), {
        'ab',
        'acdef',
        'acdz'
      })
      trie:tryRemove('acdef')
      return helpers.assertSameContents(trie:getAllEntries(), {
        'ab',
        'acdz'
      })
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
