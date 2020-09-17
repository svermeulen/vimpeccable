local assert = require("vimp.util.assert")
local log = require("vimp.util.log")
local helpers = require("vimp.testing.helpers")
local UniqueTrie = require("vimp.unique_trie")
local Tester
do
  local _class_0
  local _base_0 = {
    test_adds = function(self)
      local trie = UniqueTrie()
      local succeeded, existing_prefix, exact_match = trie:try_add('abc')
      assert.that(succeeded)
      assert.that(existing_prefix == nil)
      assert.that(not exact_match)
      succeeded, existing_prefix, exact_match = trie:try_add('abc')
      assert.that(not succeeded)
      assert.that(existing_prefix == 'abc')
      assert.that(exact_match)
      succeeded, existing_prefix, exact_match = trie:try_add('abcd')
      assert.that(not succeeded)
      assert.that(existing_prefix == 'abc')
      assert.that(not exact_match)
      succeeded, existing_prefix, exact_match = trie:try_add('abxyz')
      assert.that(succeeded)
      assert.that(existing_prefix == nil)
      assert.that(not exact_match)
      succeeded, existing_prefix, exact_match = trie:try_add('a')
      assert.that(not succeeded)
      assert.that(existing_prefix == 'a')
      assert.that(not exact_match)
      helpers.assert_same_contents(trie:get_all_entries(), {
        'abc',
        'abxyz'
      })
      helpers.assert_same_contents(trie:get_all_suffixes(''), {
        'abc',
        'abxyz'
      })
      helpers.assert_same_contents(trie:get_all_suffixes('a'), {
        'bc',
        'bxyz'
      })
      helpers.assert_same_contents(trie:get_all_suffixes('ab'), {
        'c',
        'xyz'
      })
      return helpers.assert_same_contents(trie:get_all_suffixes('abc'), { })
    end,
    test_remove = function(self)
      local trie = UniqueTrie()
      local succeeded, existing_prefix, exact_match = trie:try_add('ab')
      assert.that(succeeded)
      helpers.assert_same_contents(trie:get_all_entries(), {
        'ab'
      })
      assert.that(not trie:try_remove('a'))
      assert.that(trie:try_remove('ab'))
      helpers.assert_same_contents(trie:get_all_entries(), { })
      succeeded, existing_prefix, exact_match = trie:try_add('ab')
      assert.that(succeeded)
      succeeded, existing_prefix, exact_match = trie:try_add('acdef')
      assert.that(succeeded)
      succeeded, existing_prefix, exact_match = trie:try_add('acdz')
      assert.that(succeeded)
      assert.that(not trie:try_remove('a'))
      assert.that(not trie:try_remove('ac'))
      assert.that(not trie:try_remove('acd'))
      helpers.assert_same_contents(trie:get_all_entries(), {
        'ab',
        'acdef',
        'acdz'
      })
      trie:try_remove('acdef')
      return helpers.assert_same_contents(trie:get_all_entries(), {
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
